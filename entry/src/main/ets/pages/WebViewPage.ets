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
      const navInfo = this.getUIContext().getHostContext();
      // FWD-REF: P-S02-001 resolve_by=Slice 2 Step 3d — navParam (url/title) from Intent extras (source: L47-48)
      // FWD-REF: P-S02-101 resolve_by=Slice 2 Step 3d — 15 WebSettings configs (source: L75-120)
      // FWD-REF: P-S02-102 resolve_by=Slice 2 Step 3d — isAgreementUrl check (source: L127-131)
      // FWD-REF: P-S02-103 resolve_by=Slice 2 Step 3d — readAgreement analytics scroll tracking (source: L138-142)
    } catch (e) {
      this.loadError = true;
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
