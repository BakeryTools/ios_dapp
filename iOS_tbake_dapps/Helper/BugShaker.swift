//
//  BugShaker.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 29/07/2021.
//

import UIKit
import MessageUI


final public class BugShaker {
    
    /// Enable or disable shake detection
    public static var isEnabled = true
    
    struct Config {
        static var recipients: [String]?
        static var subject: String?
        static var body: String?
    }
    
    // MARK: - Configuration
    
    /**
     Set bug report email recipient(s), custom subject line and body.
     
     - Parameters:
     - recipients: List of email addresses to which the report will be sent.
     - subject:      Custom subject line to use for the report email.
     - body:         Custom email body (plain text).
     */
    public class func configure(to recipients: [String], subject: String?, body: String? = nil) {
        Config.recipients = recipients
        Config.subject = subject
        Config.body = body
    }
    
}

extension UIViewController: MFMailComposeViewControllerDelegate {
    
    // MARK: - UIResponder
    
    override open var canBecomeFirstResponder: Bool {
        return true
    }
    
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard BugShaker.isEnabled && motion == .motionShake else { return }
        
        presentReportPrompt { [weak self] (action) in
            guard let self = self else { return }
            self.presentDescriptionPrompt()
        }
    }
    
    // MARK: - Alert
    func presentDescriptionPrompt() {
        let ac = UIAlertController(title: R.string.localizable.sendBugDetails(), message: R.string.localizable.pleaseElaborateBug(), preferredStyle: .alert)
        ac.addTextField()

        let submitAction = UIAlertAction(title: R.string.localizable.send(), style: .default) { [unowned ac, weak self] _ in
            guard let self = self else { return }
            let answer = ac.textFields?[0].text

            if !(answer?.isEmpty ?? false) {
                BugShaker.Config.body = (BugShaker.Config.body ?? "") + """
                <strong>Description:</strong> \(answer ?? "")
                """
            }
            
            let cachedScreenshot = self.captureScreenshot()
            self.presentReportComposeView(cachedScreenshot)
        }

        let cancelAction = UIAlertAction(title: R.string.localizable.cancel(), style: .cancel)
        
        ac.addAction(submitAction)
        ac.addAction(cancelAction)

        present(ac, animated: true)
    }
    
    @objc func presentReportPrompt(_ reportActionHandler: @escaping (UIAlertAction) -> Void) {
        let preferredStyle: UIAlertController.Style

        if UIDevice.current.userInterfaceIdiom == .pad {
            preferredStyle = .alert
        } else {
            preferredStyle = .actionSheet
        }

        let alertController = UIAlertController(
            title: R.string.localizable.shakeDetected(),
            message: R.string.localizable.wouldYouLikeReportABug(),
            preferredStyle: preferredStyle
        )
        
        let reportAction = UIAlertAction(title: R.string.localizable.reportABug(), style: .default, handler: reportActionHandler)
        let cancelAction = UIAlertAction(title: R.string.localizable.cancel(), style: .cancel)
        
        alertController.addAction(reportAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    // MARK: - Report methods
    
    /**
     Take a screenshot for the current screen state.
     
     - returns: Screenshot image.
     */
    @objc func captureScreenshot() -> UIImage? {
        guard let window = getKeyWindow() else { return nil }

        UIGraphicsBeginImageContextWithOptions(window.frame.size,
                                               true,
                                               window.screen.scale)

        defer { UIGraphicsEndImageContext() }

        window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)

        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /**
     Present the user with a mail compose view with the recipient(s), subject line and body
     pre-populated, and the screenshot attached.
     
     - parameter screenshot: The screenshot to attach to the report.
     */
    func presentReportComposeView(_ screenshot: UIImage?) {
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            
            guard let toRecipients = BugShaker.Config.recipients else {
                print("BugShaker – Error: No recipients provided. Make sure that BugShaker.configure() is called.")
                return
            }
            
            mailComposer.setToRecipients(toRecipients)
            mailComposer.setSubject(BugShaker.Config.subject ?? "Bug Report")
            mailComposer.setMessageBody(BugShaker.Config.body ?? "", isHTML: true)
            mailComposer.mailComposeDelegate = self
            
            if let screenshot = screenshot, let screenshotJPEG = screenshot.jpegData(compressionQuality: CGFloat(1.0)) {
                mailComposer.addAttachmentData(screenshotJPEG, mimeType: "image/jpeg", fileName: "screenshot.jpeg")
            }
            
            present(mailComposer, animated: true, completion: nil)
        }
    }
    
    // MARK: - MFMailComposeViewControllerDelegate
    
    open func mailComposeController(_ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult, error: Error?) {
        if let error = error {
            print("BugShaker – Error: \(error)")
        }
        
        switch result {
        case .failed:
            print("BugShaker – Bug report send failed.")
            break
            
        case .sent:
            print("BugShaker – Bug report sent!")
            break

        default:
            // noop
            break
        }

        dismiss(animated: true, completion: nil)
    }

}

