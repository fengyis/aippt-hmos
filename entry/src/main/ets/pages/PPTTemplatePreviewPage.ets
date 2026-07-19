import { AppTitleBar } from '../components/AppTitleBar'
import { StepIndicator, StepData } from '../components/StepIndicator'
import { PPTCoverImage } from '../components/PPTCoverImage'
import { PptViewModel } from '../viewmodel/PptViewModel'

@ObservedV2
class TemplatePreviewState {
  @Trace covers: string[] = []
  @Trace templateName: string = ''
  @Trace hasOutline: boolean = false
  @Trace isLoading: boolean = false
}

@Entry
@ComponentV2
struct PPTTemplatePreviewPage {
  @Consumer('navPathStack') navPathStack: NavPathStack = new NavPathStack()
  @Local state: TemplatePreviewState = new TemplatePreviewState()
  @Local pptVM: PptViewModel = new PptViewModel()

  aboutToAppear(): void {
    this.state.covers = this.pptVM.selectedTemplate?.getCoverList() ?? []
    this.state.templateName = this.pptVM.selectedTemplate?.templateName ?? '模板预览'
  }

  async onGeneratePPT(): Promise<void> {
    if (this.state.hasOutline) {
      await this.pptVM.createPpt()
    } else {
      this.navPathStack.pushPathByName('CreateOutLinePage', undefined)
    }
  }

  build() {
    NavDestination() {
      Column() {
        AppTitleBar({ title: this.state.templateName, showBack: true,
          onBackClick: () => this.navPathStack.pop() })

        StepIndicator({ steps: [
          new StepData('1', '选择模版'), new StepData('2', '输入主题'),
          new StepData('3', '生成大纲'), new StepData('4', '生成PPT')
        ], currentStep: this.state.hasOutline ? 3 : 1 })

        Scroll() {
          List({ space: 13 }) {
            ForEach(this.state.covers, (url: string) => {
              ListItem() { PPTCoverImage({ coverUrl: url, borderRadius: 8 }).width('85%') }
            })
          }
          .listDirection(Axis.Horizontal)
          .width('100%')
          .height(300)
        }
        .margin({ top: 16 })

        Blank()
        Button(this.state.hasOutline ? 'AI生成PPT' : '生成PPT')
          .fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.White)
          .width(220).height(48).borderRadius(24)
          .backgroundColor('#5B3CFF')
          .margin({ bottom: 24 })
          .onClick(() => this.onGeneratePPT())
      }
      .width('100%').height('100%').backgroundColor(Color.White)
    }
    .title('').hideTitleBar(true)
  }
}
