import { AppStorageV2 } from '@kit.ArkUI';

class WebViewParams {
  url: string = '';
  title: string = '';
}

@ObservedV2
class AboutUsState {
  @Trace versionName: string = '1.0.0';
  @Trace recordNumber: string = '';
}

@Entry
@ComponentV2
struct AboutUsPage {
  @Consumer('navPathStack') navPathStack: NavPathStack = new NavPathStack();
  @Local state: AboutUsState = AppStorageV2.connect(
    AboutUsState, 'aboutUsState', () => new AboutUsState()
  )!;

  aboutToAppear(): void {
    try {
      this.state.versionName = '1.0.0';
      this.state.recordNumber = '';
    } catch (e) {
      // use defaults
    }
  }

  // Agreement URLs: privacy/terms links loaded from config
  getAgreementUrl(type: string): string {
    if (type === 'user') {
      return 'about:blank?type=user_agreement';
    }
    return 'about:blank?type=privacy_agreement';
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

        Text($r('app.string.str_about_us'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .layoutWeight(1)
          .textAlign(TextAlign.Center);
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 });

      Scroll() {
        Column() {
          Image($r('app.media.icon_app_logo'))
            .width(88)
            .height(88)
            .margin({ top: 80 });

          Text($r('app.string.appName'))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#222222')
            .margin({ top: 10 });

          Text(this.state.versionName)
            .fontSize(14)
            .fontColor('#222222')
            .margin({ top: 8 });

          Column() {
            this.SettingBarItem($r('app.string.user_agreement'), () => {
              const params = new WebViewParams();
              params.url = this.getAgreementUrl('user');
              params.title = '用户协议';
              this.navPathStack.pushPathByName('WebViewPage', params);
            });
            this.SettingBarItem($r('app.string.privacy_agreement'), () => {
              const params = new WebViewParams();
              params.url = this.getAgreementUrl('privacy');
              params.title = '隐私协议';
              this.navPathStack.pushPathByName('WebViewPage', params);
            });
            this.SettingBarItem($r('app.string.algorithm_filing'), () => {
              this.getUIContext().showAlertDialog({
                title: '算法备案公示',
                message: '算法名称：\n讯飞星火认知大模型算法\n备案编号：\n网信算备340104764864601230021号\n备案状态：\n正常',
                confirm: { value: '确定', action: () => {} }
              });
            });
          }
          .width('calc(100% - 40vp)')
          .borderRadius(14)
          .backgroundColor(Color.White)
          .margin({ top: 20 });

          Text(this.state.recordNumber)
            .fontSize(14)
            .fontColor('#222222')
            .margin({ bottom: 20, top: 20 });
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center);
      }
      .layoutWeight(1);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }

  @Builder
  SettingBarItem(label: Resource, onClick: () => void): void {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#333534')
        .layoutWeight(1);
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor(['#999999']);
    }
    .width('100%')
    .height(54)
    .padding({ left: 20, right: 20 })
    .onClick(onClick);
  }
}
