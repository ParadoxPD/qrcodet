default:
	flutter clean
	flutter pub get
	flutter run

create:
	flutter pub get
	dart run flutter_launcher_icons:main
	flutter clean
	flutter pub get
	flutter build apk --release
	cp build/app/outputs/flutter-apk/app-release.apk ../release/qrcodet-release.apk
	flutter install


