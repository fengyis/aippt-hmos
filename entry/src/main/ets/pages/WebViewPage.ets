import { webview } from '@kit.ArkWeb';
import { AppStorageV2 } from '@kit.ArkUI';

@ObservedV2
class WebViewPageParams {
  @Trace pageUrl: string = '';
  @Trace pageTitle: string = '';
}

@Entry
@ComponentV2
struct WebViewPage {
  @Consumer('navPathStack') navPathStack: NavPathStack = new NavPathStack();
  @Local params: WebViewPageParams = AppStorageV2.connect(
    WebViewPageParams, 'webViewPageParams', () => new WebViewPageParams()
  )!;
  @Local isLoading: boolean = true;
  @Local loadError: boolean = false;
  private webController: webview.WebviewController = new webview.WebviewController();

  aboutToAppear(): void {
    try {
      const navInfo = this.queryNavInfo()
      if (navInfo && navInfo.param) {
        const p = navInfo.param as Record<string, string>
        if (p['url']) { this.params.pageUrl = p['url'] }
        if (p['title']) { this.params.pageTitle = p['title'] }
      }
    } catch (e) {
      this.loadError = true
    }
  }

  private queryNavInfo(): NavDestinationInfo | null {
    return this.getUIContext().getNavDestinationState()
  }
  }

  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(22)
          .fontColor([Color.Black])
          .onClick(() => {
            this.navPathStack.pop();
          });

        Text(this.params.pageTitle)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .layoutWeight(1)
          .textAlign(TextAlign.Center);
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White);

      if (this.loadError) {
        Text($r('app.string.load_error'))
          .fontSize(14)
          .fontColor('#999')
          .layoutWeight(1)
          .textAlign(TextAlign.Center);
      } else {
        Web({ src: this.params.pageUrl, controller: this.webController })
          .layoutWeight(1)
          .width('100%')
          .onPageBegin(() => { this.isLoading = true; })
          .onPageEnd(() => { this.isLoading = false; })
          .onErrorReceive(() => { this.loadError = true; });
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White);
  }
}
