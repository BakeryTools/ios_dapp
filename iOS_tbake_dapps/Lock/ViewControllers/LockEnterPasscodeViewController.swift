// Copyright SIX DAY LLC. All rights reserved.
// Copyright © 2018 Stormbird PTE. LTD.

import UIKit
import LocalAuthentication

class LockEnterPasscodeViewController: LockPasscodeViewController {
	private lazy var lockEnterPasscodeViewModel: LockEnterPasscodeViewModel? = {
		return model as? LockEnterPasscodeViewModel
	}()
	private var context: LAContext!
	private var canEvaluatePolicy: Bool {
		return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
	}

	var unlockWithResult: ((_ success: Bool, _ bioUnlock: Bool) -> Void)?

	override func viewDidLoad() {
		super.viewDidLoad()
		lockView.lockTitle.text = lockEnterPasscodeViewModel?.initialLabelText
	}
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		//If max attempt limit is reached we should validate if one minute gone.
		if lock.isIncorrectMaxAttemptTimeSet {
			lockView.lockTitle.text = lockEnterPasscodeViewModel?.tryAfterOneMinute
			maxAttemptTimerValidation()
		}
	}
	func showBioMetricAuth() {
		context = LAContext()
		touchValidation()
	}
    
	override func enteredPasscode(_ passcode: String) {
		super.enteredPasscode(passcode)
		if lock.isPasscodeValid(passcode: passcode) {
			lock.resetPasscodeAttemptHistory()
			lock.removeIncorrectMaxAttemptTime()
			lockView.lockTitle.text = lockEnterPasscodeViewModel?.initialLabelText
			unlock(withResult: true, bioUnlock: false)
		} else {
			let numberOfAttempts = lock.numberOfAttempts
			let passcodeAttemptLimit = model.passcodeAttemptLimit
			let text = R.string.localizable.lockEnterPasscodeViewModelIncorrectPasscode(passcodeAttemptLimit - numberOfAttempts)
			lockView.lockTitle.text = text
			lockView.shake()
			if numberOfAttempts >= passcodeAttemptLimit {
				exceededLimit()
				return
			}
			lock.recordIncorrectPasscodeAttempt()
		}
	}
	private func exceededLimit() {
		lockView.lockTitle.text = lockEnterPasscodeViewModel?.tryAfterOneMinute
		lock.recordIncorrectMaxAttemptTime()
		hideKeyboard()
	}
	private func maxAttemptTimerValidation() {
		let now = Date()
		let maxAttemptTimer = lock.recordedMaxAttemptTime
		let interval = now.timeIntervalSince(maxAttemptTimer)
		//if interval is greater or equal 60 seconds we give 1 attempt.
		if interval >= 60 {
			lockView.lockTitle.text = lockEnterPasscodeViewModel?.initialLabelText
			showKeyboard()
		}
	}
	private func unlock(withResult success: Bool, bioUnlock: Bool) {
		view.endEditing(true)
		if let unlock = unlockWithResult {
			unlock(success, bioUnlock)
		}
	}

	private func touchValidation() {
		guard canEvaluatePolicy, let reason = lockEnterPasscodeViewModel?.loginReason else {
			return
		}
		hideKeyboard()
		context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, _ in
            guard let self = self else { return }
			DispatchQueue.main.async {
				if success {
					self.lock.resetPasscodeAttemptHistory()
					self.lock.removeIncorrectMaxAttemptTime()
					self.lockView.lockTitle.text = self.lockEnterPasscodeViewModel?.initialLabelText
					self.unlock(withResult: true, bioUnlock: true)
				} else {
					self.showKeyboard()
				}
			}
		}
	}
}
