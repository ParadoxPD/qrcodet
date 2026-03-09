default:
	flutter clean
	flutter pub get
	flutter run

create:
	flutter clean
	flutter pub get
	dart run flutter_launcher_icons:main
	flutter build apk --release
	cp build/app/outputs/flutter-apk/app-release.apk ./release/qrcodet-release.apk
	flutter install


