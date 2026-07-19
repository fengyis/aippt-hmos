import { AppTitleBar } from '../components/AppTitleBar'
import { PPTCoverImage } from '../components/PPTCoverImage'

@ObservedV2
class PPTFileState {
  @Trace pptTitle: string = ''
  @Trace images: string[] = []
  @Trace isLoading: boolean = false
  @Trace isPreviewReady: boolean = false
  @Trace isFromWorksPage: boolean = false
}

@Entry
@ComponentV2
struct PPTFilePage {
  @Consumer('navPathStack') navPathStack: NavPathStack = new NavPathStack()
  @Local state: PPTFileState = new PPTFileState()

  aboutToAppear(): void {
    // FWD-REF: P-S04-005 resolve_by=Slice 4 Step 3c — parse route params + download PPTX → convert to images
  }

  build() {
    NavDestination() {
      Column() {
        AppTitleBar({ title: this.state.pptTitle, showBack: true,
          onBackClick: () => this.navPathStack.pop() })

        if (this.state.isLoading) {
          LoadingProgress().width(48).height(48).margin({ top: 100 })
        } else if (this.state.isPreviewReady) {
          List() {
            ForEach(this.state.images, (url: string) => {
              ListItem() {
                PPTCoverImage({ coverUrl: url, borderRadius: 3 })
              }
            })
          }
          .layoutWeight(1).scrollBar(BarState.Off)
          .margin({ top: 8 })

          Button($r('app.string.generate_ppt'))
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.White)
            .width('100%').height(50).borderRadius(10)
            .backgroundColor('#5B3CFF')
            .margin({ left: 16, right: 16, bottom: 24 })
        }
      }
      .width('100%').height('100%').backgroundColor('#F7F7F7')
    }.title('').hideTitleBar(true)
  }
}
