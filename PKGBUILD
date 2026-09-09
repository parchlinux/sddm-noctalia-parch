pkgname=sddm-noctalia-parch
pkgver=1.0
pkgrel=1
pkgdesc="Noctalia SDDM theme for Parch"
arch=('any')
license=('MIT')
depends=('sddm' 'ttf-google-sans')

source=(
    "Main.qml"
    "metadata.desktop"
    "background.png"
    "logo.svg"
)

sha256sums=(
    'bb43adb42b47d0cb4402f67086bdfec03e63c0a2069f04ef2521dac7f9fb9eed'
    'e65a6cde970ad4ae50612ee97166e4e5bf1031573d49b89cca80ee8a307b40e2'
    'f486de13a636812014804213b6e9c70c6c32c70389a6f2491a80fc84ce9a3c8d'
    '50d8a95a5bc2e7f19852b30c7701d98145788d7c9ffd9ee170cc39194155c88a'
)

package() {
    install -dm755 "$pkgdir/usr/share/sddm/themes/noctalia-parch"

    install -Dm644 "$srcdir/Main.qml" \
        "$pkgdir/usr/share/sddm/themes/noctalia-parch/Main.qml"

    install -Dm644 "$srcdir/metadata.desktop" \
        "$pkgdir/usr/share/sddm/themes/noctalia-parch/metadata.desktop"

    install -Dm644 "$srcdir/background.png" \
        "$pkgdir/usr/share/sddm/themes/noctalia-parch/background.png"

    install -Dm644 "$srcdir/logo.svg" \
        "$pkgdir/usr/share/sddm/themes/noctalia-parch/logo.svg"
    

}