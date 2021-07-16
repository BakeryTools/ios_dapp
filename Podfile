# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

target 'iOS_tbake_dapps' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for iOS_tbake_dapps
  #https://github.com/ninjaprox/NVActivityIndicatorView
  pod 'NVActivityIndicatorView'

  # https://github.com/hackiftekhar/IQKeyboardManager
  pod 'IQKeyboardManagerSwift'
  
  #https://github.com/jrendel/SwiftKeychainWrapper
  pod 'SwiftKeychainWrapper'

  #https://material.io/develop/ios/components/page-controls/
  pod 'CHIPageControl/Jalapeno'

  # https://github.com/onevcat/Kingfisher
  pod 'Kingfisher'
  
  pod 'BigInt', '~> 3.1'
  pod 'R.swift'
  pod 'JSONRPCKit', '~> 2.0.0'
  pod 'APIKit'
  pod 'Eureka', :git=> 'https://github.com/xmartlabs/Eureka.git', :commit => '5c54e2607632ce586010e50e91d9adcb6bb3909e'
  pod 'MBProgressHUD'
  pod 'StatefulViewController'

  pod 'QRCodeReaderViewController', :git=>'https://github.com/AlphaWallet/QRCodeReaderViewController.git', :commit=>'30d1a2a7d167d0d207ae0ae3a4d81bcf473d7a65'
  pod 'KeychainSwift', :git=>'https://github.com/AlphaWallet/keychain-swift.git', :commit=> 'b797d40a9d08ec509db4335140cf2259b226e6a2'
  pod 'SwiftLint'
  pod 'SeedStackViewController'
  pod 'RealmSwift', '5.5.1'
  pod 'Moya', '~> 10.0.1'
  pod 'JavaScriptKit'
  pod 'CryptoSwift', '~> 1.0'
  pod 'SwiftyXMLParser', :git => 'https://github.com/yahoojapan/SwiftyXMLParser.git'
  pod 'AlphaWalletWeb3Provider', :git=>'https://github.com/AlphaWallet/AlphaWallet-web3-provider', :commit => '308dbd3c7f70487b90aabdeef8641b7ad959c26f'
  pod 'TrezorCrypto', :git=>'https://github.com/AlphaWallet/trezor-crypto-ios.git', :commit => '50c16ba5527e269bbc838e80aee5bac0fe304cc7'
  pod 'TrustKeystore', :git => 'https://github.com/alpha-wallet/trust-keystore.git', :commit => 'c0bdc4f6ffc117b103e19d17b83109d4f5a0e764'
  pod 'SwiftyJSON'
  pod 'web3swift', :git => 'https://github.com/AlphaWallet/web3swift.git', :commit=> 'cce12b1c421f18b5768e5249a8343932737a51fe'
  pod 'SAMKeychain'
  pod 'PromiseKit/CorePromise'
  pod 'PromiseKit/Alamofire'
  pod "Kanna", :git => 'https://github.com/tid-kijyun/Kanna.git', :commit => '06a04bc28783ccbb40efba355dee845a024033e8'
  pod 'TrustWalletCore'
  pod 'AWSSNS'
  pod 'Mixpanel-swift'
  pod 'UnstoppableDomainsResolution', '0.1.6'
  pod 'BlockiesSwift'
  pod 'PaperTrailLumberjack/Swift'
  pod 'WalletConnectSwift', :git => 'https://github.com/WalletConnect/WalletConnectSwift.git', :commit => 'c86938785303b99ff09d90e32e553ce38eee0aa6'
  pod 'AssistantKit'
  
  target 'iOS_tbake_dappsTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'iOS_tbake_dappsUITests' do
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    
    if ['TrustKeystore'].include? target.name
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Owholemodule'
      end
    end
    if ['Result', 'SwiftyXMLParser', 'JSONRPCKit'].include? target.name
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '4.2'
      end
    end
    
    target.build_configurations.each do |config|
      if ['Kingfisher'].include? target.name
        #no op
      else
        #xCode 12 requires minimum IPHONEOS_DEPLOYMENT_TARGET 9.0
        if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] <= '8.0'
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0';
        end
      end
      #WalletConnectSwift requires minimum deploy target 11.0
      if ['WalletConnectSwift'].include? target.name
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0';
      end
    end
  end
end
