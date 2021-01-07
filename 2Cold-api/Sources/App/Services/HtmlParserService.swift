import Foundation
import AppFoundation
import SwiftSoup
import Vapor

enum PageType: String {
    case login
    case roomSelection
    case freezersInfo
    case unknown
}

struct ASPNetState {
    let viewState: String
    let eventValidation: String
}

class HtmlParserService {

    private let logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    func pageType(_ document: Document) -> PageType {
        do {
            var element = try document.select("title").first()
            let text = try element?.text()
            if text == "TAC Vista ScreenMate - Login" {
                return .login
            }
            if text == "TAC Vista ScreenMate" {
                return .roomSelection
            }
            element = try document.select("a[id^=dataList_toggle_]").first()
            if element != nil {
                return .freezersInfo
            }
        } catch let error {
            logger.report(error: error)
            return .unknown
        }
        return .unknown
    }

    func floor(_ document: Document) -> Int? {
        do {
            let element = try document.select("input[id=roomId]").first()
            let value = try element?.val()
            switch value {
            case Constants.room5Floor:
                return 5
            case Constants.room8Floor:
                return 8
            default:
                return nil
            }
        } catch let error {
            logger.report(error: error)
            return nil
        }
    }

    func extractState(_ document: Document) -> ASPNetState {
        do {
            let viewStateElements = try document.select("input[id=__VIEWSTATE]")
            let eventValidationElements = try document.select("input[id=__EVENTVALIDATION]")
            let viewState = try viewStateElements.first()?.val() ?? ""
            let eventValidation = try eventValidationElements.first()?.val() ?? ""
            return ASPNetState(viewState: viewState, eventValidation: eventValidation)
        } catch let error {
            logger.report(error: error)
            return ASPNetState(viewState: "", eventValidation: "")
        }
    }

    func extractFreezers(_ document: Document, floor: Int, storage: [FreezerStorable]) -> [Freezer] {
        return storage
            .filter { $0.floor == floor }
            .map {
                return $0.makeFreezer(isEnabled: isEnabled(document, freezer: $0))
            }
    }

    func isEnabled(_ document: Document, freezer: FreezerStorable) -> Bool {
        do {
            let toggleId = "dataList_toggle_\(freezer.toggleCommandId)"
            let selector = "a[id=\(toggleId)] > span"
            let elements = try document.select(selector)
            return try elements.first()?.text() == "1"
        } catch let error {
            logger.report(error: error)
            return false
        }
    }
}
