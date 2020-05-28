//
//  ExposureNotificationJSBridge.swift
//  safesafe
//
//  Created by Lukasz szyszkowski on 17/05/2020.
//

import Foundation
import PromiseKit
import ExposureNotification

protocol ExposureNotificationJSProtocol: class {
    
    func enableService(enable: Bool) -> Promise<Void>
    func getExposureSummary() -> Promise<ExposureSummary>

}

@available(iOS 13.5, *)
final class ExposureNotificationJSBridge: ExposureNotificationJSProtocol {
    
    // MARK: - Properties
    
    private let exposureService: ExposureServiceProtocol
    private let exposureSummaryService: ExposureSummaryServiceProtocol
    private let exposureStatus: ExposureNotificationStatusProtocol
    private var viewController: UIViewController?
    
    // MARK: - Life Cycle

    init(
        exposureService: ExposureServiceProtocol,
        exposureSummaryService: ExposureSummaryServiceProtocol,
        exposureStatus: ExposureNotificationStatusProtocol,
        viewController: UIViewController
    ) {
        self.exposureService = exposureService
        self.exposureSummaryService = exposureSummaryService
        self.exposureStatus = exposureStatus
        self.viewController = viewController
    }
    
    // MARK: - Public methods
    
    func enableService(enable: Bool) -> Promise<Void> {
        (enable ? turnOnService() : exposureService.setExposureNotificationEnabled(false))
            .recover { error -> Guarantee<()> in
                guard let error = error as? ENError else {
                    return .value
                }
                
                switch error.code {
                case .notEnabled:
                    console("ENA not enabled", type: .warning)
                case .restricted:
                    console("ENA retrictedf", type: .warning)
                case .invalidated:
                    console("ENA invalidated", type: .warning)
                case .notAuthorized:
                    console("ENA Not authorized")
                default:
                    console("ENA Error code")
                }
                
                return .value
        }
    }
    
    func getExposureSummary() -> Promise<ExposureSummary> {
        Promise { seal in
            firstly {
                when(fulfilled: [exposureService.detectExposures()])
            }.done { _ in
                seal.fulfill(self.exposureSummaryService.getExposureSummary())
            }.catch {
                seal.reject($0)
            }
        }
    }
    
    // MARK: - Private methods
    
    private func turnOnService() -> Promise<Void> {
        return exposureService.setExposureNotificationEnabled(true)
            .recover { [weak self] error -> Promise<Void> in
                guard let self = self else {
                    return .init(error: InternalError.deinitialized)
                }
                
                if let error = error as? ENError {
                    switch error.code {
                    case .notAuthorized:
                        return self.showAlert(for: .exposureNotification)
                    default:
                        return .value
                    }
                } else {
                    return .value
                }
        }.then { _ -> Promise<Bool> in
            return self.exposureStatus.isBluetoothOn
        }.then {[weak self] isOn -> Promise<Void> in
            guard let self = self else {
                return .init(error: InternalError.deinitialized)
            }
            
            return isOn ? .value : self.showAlert(for: .bluetooth)
        }
    }
    
    private func showAlert(for permission: Permissions.Permission) -> Promise<Void> {
        guard let viewController = viewController else { return .init(error: InternalError.nilValue) }
        return Permissions.instance.choiceAlert(for: permission, on: viewController)
            .then { action -> Promise<Void> in
                guard action == .skip else {  return .init(error: PMKError.cancelled) }
                return .value
        }
    }
}