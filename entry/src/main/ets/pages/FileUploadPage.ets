import { AppTitleBar } from '../components/AppTitleBar'

@Entry
@ComponentV2
struct FileUploadPage {
  @Consumer('navPathStack') navPathStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column() {
        AppTitleBar({ title: '上传文档', showBack: true,
          onBackClick: () => this.navPathStack.pop() })

        Column() {
          Text($r('app.string.file_upload_format_hint'))
            .fontSize(12).fontColor('#979797').textAlign(TextAlign.Center)
        }
        .layoutWeight(1).justifyContent(FlexAlign.Center)

        Button($r('app.string.click_to_upload'))
          .fontSize(18).fontWeight(FontWeight.Bold).fontColor(Color.White)
          .width('100%').height(57).borderRadius(10)
          .backgroundColor('#5B3CFF')
          .margin({ left: 20, right: 20, bottom: 80 })
          .onClick(() => this.navPathStack.pushPathByName('FileListPage', undefined))
      }
      .width('100%').height('100%')
      .backgroundColor('#F2F6FF')
    }.title('').hideTitleBar(true)
  }
}
