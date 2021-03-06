//
//  DependencyContainer.swift
//  safesafe
//

import ExposureNotification
import Moya
import FirebaseRemoteConfig

final class DependencyContainer {
    
    @available(iOS 13.5, *)
    lazy var backgroundTaskService = BackgroundTasksService(
        exposureService: exposureService,
        districtsService: districtsService,
        dashboardWorker: dashboardWorker
    )
    
    lazy var deviceCheckService = DeviceCheckService()
    lazy var exposureServiceDebug = ExposureServiceDebug()
    lazy var fileStorage = FileStorage()
    
    @available(iOS 13.5, *)
    lazy var diagnosisKeysDownloadService = DiagnosisKeysDownloadService(
        with: remoteConfiguration,
        exposureKeysProvider: MoyaProvider<ExposureKeysTarget>(session: CustomSession.defaultSession(), plugins: [CachePolicyPlugin()]),
        localStorage: realmLocalStorage
    )
    
    @available(iOS 13.5, *)
    lazy var diagnosisKeysUploadService = DiagnosisKeysUploadService(
        with: exposureService,
        deviceCheckService: deviceCheckService,
        exposureKeysProvider: MoyaProvider<ExposureKeysTarget>(session: CustomSession.defaultSession(), plugins: [CachePolicyPlugin()])
    )
    
    @available(iOS 13.5, *)
    lazy var exposureService = ExposureService(
        exposureManager: ENManager(),
        diagnosisKeysService: diagnosisKeysDownloadService,
        configurationService: remoteConfiguration,
        storageService: realmLocalStorage
    )
    
    @available(iOS 13.5, *)
    lazy var exposureSummaryService: ExposureSummaryServiceProtocol = ExposureSummaryService(
        storageService: realmLocalStorage,
        freeTestService: freeTestService
    )

    lazy var infoProvider: MoyaProvider<InfoTarget> = MoyaProvider<InfoTarget>(
        session: CustomSession.defaultSession(),
        plugins: [CachePolicyPlugin()]
    )
    
    lazy var districtsService: DistrictService = DistrictService(
        with:  MoyaProvider<InfoTarget>(session: CustomSession.defaultSession(), plugins: [CachePolicyPlugin()])
    )

    lazy var timestampsWorker: TimestampsWorkerType = TimestampsWorker(
        timestampsProvider: infoProvider,
        fileStorage: fileStorage
    )
    
    lazy var dashboardWorker: DashboardWorkerType = DashboardWorker(
        dashboardProvider: infoProvider,
        timestampsWorker: timestampsWorker,
        fileStorage: fileStorage
    )

    lazy var detailsWorker: DetailsWorkerType = DetailsWorker(
        detailsProvider: infoProvider,
        timestampsWorker: timestampsWorker,
        fileStorage: fileStorage
    )

    lazy var freeTestService: FreeTestService = FreeTestService(
        with: realmLocalStorage,
        deviceCheckService: deviceCheckService,
        apiProvider: MoyaProvider<FreeTestTarget>(session: CustomSession.defaultSession(), plugins: [CachePolicyPlugin()]),
        configuration: remoteConfiguration
    )
    
    lazy var historicalDataWorker: HistoricalDataWorkerType = HistoricalDataWorker(
        notificationsHistoryWorker: notificationHistoryWorker,
        exposureHistoricalDataService: exposureHistoricalService
    )
    
    lazy var notificationPayloadParser = NotificationUserInfoParser()
    lazy var notificationHistoryWorker: NotificationHistoryWorkerType = NotificationHistoryWorker(storage: realmLocalStorage)
    lazy var exposureHistoricalService: ExposureServiceHistoricalDataProtocol = ExposureServiceHistoricalData(storageService: realmLocalStorage)
    lazy var jailbreakService: JailbreakServiceProtocol = JailbreakService()
    lazy var openerService: OpenerServiceType = OpenerService()
    lazy var jsBridge = JSBridge(serviceStatusManager: serviceStatusManager, openerService: openerService)
    lazy var realmLocalStorage = RealmLocalStorage()
    
    lazy var remoteConfigSetting: RemoteConfigSettings = {
        let settings = RemoteConfigSettings()
        settings.fetchTimeout = 10
        return settings
    }()
    lazy var remoteConfiguration = RemoteConfiguration(settings: remoteConfigSetting)
    
    lazy var serviceStatusManager: ServiceStatusManagerProtocol = {
        if #available(iOS 13.5, *) {
            return ServiceStatusManager(
                notificationManager: NotificationManager.shared,
                exposureNotificationStatus: exposureService
            )
        } else {
            return ServiceStatusManager(
                notificationManager: NotificationManager.shared,
                exposureNotificationStatus: ExposureNotificationStatusMock()
            )
        }
    }()
    
    init() {
        RealmLocalStorage.setupEncryption()
    }
}
