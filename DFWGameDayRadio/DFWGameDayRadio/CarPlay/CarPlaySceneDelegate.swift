import CarPlay
import UIKit

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?
    private let templateManager = CarPlayTemplateManager()

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        templateManager.interfaceController = interfaceController

        let rootTemplate = templateManager.buildRootTemplate()
        interfaceController.setRootTemplate(rootTemplate, animated: true, completion: nil)

        // If audio is already playing, start score metadata updates
        if GameCoordinator.shared.isPlaying {
            templateManager.startScoreMetadataUpdates()
        }
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
        templateManager.interfaceController = nil
        templateManager.tearDown()
    }
}
