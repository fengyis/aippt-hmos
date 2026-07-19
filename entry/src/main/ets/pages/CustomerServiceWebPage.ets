import { webview } from '@kit.ArkWeb'
import { AppTitleBar } from '../components/AppTitleBar'
import { WebViewViewModel } from '../viewmodel/WebViewViewModel'

@Entry
@ComponentV2
struct CustomerServiceWebPage {
  @Consumer('navPathStack') navPathStack: NavPathStack = new NavPathStack()
  webController: webview.WebviewController = new webview.WebviewController()
  @Local vm: WebViewViewModel = new WebViewViewModel()

  aboutToAppear(): void {
    // URL loaded by WebViewViewModel.load()
    this.vm.load('about:blank', '联系客服')
  }

  build() {
    NavDestination() {
      Column() {
        AppTitleBar({ title: this.vm.title, showBack: true, onBackClick: () => this.navPathStack.pop() })
        Web({ src: this.vm.url, controller: this.webController })
          .javaScriptAccess(true)
          .domStorageAccess(true)
          .layoutWeight(1)
      }
      .width('100%').height('100%').backgroundColor(Color.White)
    }
    .title('').hideTitleBar(true)
  }
}
