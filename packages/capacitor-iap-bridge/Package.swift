// swift-tools-version: 5.9
import PackageDescription

// Package/product name is "CapacitorIapBridge" (not "CapacitorIAPBridge")
// to match exactly what `npx cap sync` derives from this plugin's
// package.json name ("capacitor-iap-bridge") into
// ios/App/CapApp-SPM/Package.swift — that file is auto-generated/
// "DO NOT MODIFY", so this name has to match its casing convention
// (capitalize each hyphen-word's first letter only, no acronym handling)
// rather than the more natural all-caps "IAP".
let package = Package(
    name: "CapacitorIapBridge",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "CapacitorIapBridge",
            targets: ["IAPBridgePlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "IAPBridgePlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/IAPBridgePlugin")
    ]
)
