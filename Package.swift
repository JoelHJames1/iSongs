// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "iSongs",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "iSongs",
            targets: ["iSongs"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        .package(url: "https://github.com/kewlbear/YoutubeDL-iOS.git", .branch("main"))
    ],
    targets: [
        .target(
            name: "iSongs",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "YoutubeDL", package: "YoutubeDL-iOS")
            ]),
        .testTarget(
            name: "iSongsTests",
            dependencies: ["iSongs"]),
    ]
)
