//
//  ChangePasswordViewController.swift
//  Roll-Pe
//
//  Created by DongHyeokHwang on 1/31/25.
//

import UIKit
import SwiftUI
import RxSwift

class ChangePasswordViewController: UIViewController {
    private let disposeBag = DisposeBag()
    
    private let userViewModel = UserViewModel()
    
    private var equalToCurrentPassword : Bool = false
    
    private let navigationBar : NavigationBar = {
        let navigationBar = NavigationBar()
        navigationBar.menuIndex = 4
        navigationBar.showSideMenu = true
        return navigationBar
    }()
    
    private let titleLabel : UILabel = {
        let label = UILabel()
        label.text = "비밀번호 변경"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .rollpeSecondary
        if let customFont = UIFont(name: "HakgyoansimDunggeunmisoOTF-R", size: 32) {
            label.font = customFont
        } else {
            label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        }
        return label
    }()
    
    private let changePasswordTextField : TextField = {
        let textField = TextField()
        textField.placeholder = "비밀번호"
        textField.textContentType = .password
        textField.isSecureTextEntry = true
        return textField
    }()
    
    private let confirmPasswordTextField : TextField = {
        let textField = TextField()
        textField.placeholder = "비밀번호 확인"
        textField.textContentType = .password
        textField.isSecureTextEntry = true
        return textField
    }()
    
    private let changeConfirmButton = PrimaryButton(title: "변경하기")

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        view.backgroundColor = .rollpePrimary
        bindData()
        setupNavigationBar()
        setupTitleLabel()
        setupChangePasswordTextField()
        setupConfirmPasswordTextField()
        setupChangeConfirmButton()
        bindPasswordTextField()
    }
    
    private func setupNavigationBar() {
        view.addSubview(navigationBar)
        navigationBar.parentViewController = self
            navigationBar.snp.makeConstraints { make in
                make.horizontalEdges.equalToSuperview().inset(20)
                make.top.equalTo(safeareaTop + 40)
            }
    }
    
    private func setupTitleLabel() {
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints{make in
            make.centerX.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom).offset(28)
        }
    }
    
    private func setupChangePasswordTextField() {
        view.addSubview(changePasswordTextField)
        changePasswordTextField.snp.makeConstraints{make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.top.equalTo(titleLabel.snp.bottom).offset(52)
        }
    }
    
    private func setupConfirmPasswordTextField() {
        view.addSubview(confirmPasswordTextField)
        confirmPasswordTextField.snp.makeConstraints{make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.top.equalTo(changePasswordTextField.snp.bottom).offset(8)
        }
    }
    
    private func setupChangeConfirmButton(){
        view.addSubview(changeConfirmButton)
        changeConfirmButton.addTarget(self, action: #selector(changeConfirmButtonTapped), for: .touchUpInside)
        changeConfirmButton.snp.makeConstraints{ make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.top.equalTo(confirmPasswordTextField.snp.bottom).offset(32)
        }
    }
    
    private func bindPasswordTextField() {
          changePasswordTextField.rx.text.orEmpty
              .debounce(.seconds(1), scheduler: MainScheduler.instance) //1초간 입력변화 없으면 호출
              .distinctUntilChanged()
              .subscribe(onNext: { [weak self] text in
                  self?.userViewModel.checkPassword(password: text)
              })
              .disposed(by: disposeBag)
      }
    
    private func bindData(){
        userViewModel.equalToCurrentPassword
            .subscribe(onNext:{[weak self] model in
                self?.equalToCurrentPassword = model ?? false
            })
            .disposed(by: disposeBag)
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func changeConfirmButtonTapped() {
        if let changePassword = changePasswordTextField.text {
            if (changePassword != ""){
                    if (changePassword != confirmPasswordTextField.text) {
                        let alert = UIAlertController(title: "오류", message: "비밀번호가 일치하지 않습니다.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                    else {
                        if (changePassword.contains(" ")) {
                            let alert = UIAlertController(title: "오류", message: "띄어쓰기는 포함될 수 없습니다", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        }
                        else if (!NSPredicate(format: "SELF MATCHES %@", "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]).{8,}$").evaluate(with: changePassword)) {
                            let alert = UIAlertController(title: "오류", message: "비밀번호는 8자 이상, 대문자, 소문자, 숫자, 특수문자를 포함해야 합니다.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        }
                        else{
                            if (equalToCurrentPassword) {
                                let alert = UIAlertController(title: "오류", message: "현재 비밀번호와 새 비밀번호가 동일합니다.", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                            }
                            else {
                                userViewModel.changePassword(password: changePassword)
                                      .subscribe(onCompleted: { [weak self] in
                                          let alert = UIAlertController(title: "성공", message: "비밀번호가 성공적으로 변경되었습니다.", preferredStyle: .alert)
                                          alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                                          self?.present(alert, animated: true, completion: nil)
                                      }, onError: { [weak self] error in
                                          let alert = UIAlertController(title: "오류", message: "비밀번호 변경 중 오류가 발생했습니다.", preferredStyle: .alert)
                                          alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                                          self?.present(alert, animated: true, completion: nil)
                                      })
                                      .disposed(by: disposeBag)
                            }
                        }
                    }
            }
            else{
                let alert = UIAlertController(title: "오류", message: "바꾸실 비밀번호를 입력해주세요", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
        else{
            let alert = UIAlertController(title: "오류", message: "바꾸실 비밀번호를 입력해주세요", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

struct ChangePasswordViewControllerPreview: PreviewProvider {
    static var previews: some View {
        UIViewControllerPreview {
            ChangePasswordViewController()
        }
    }
}
