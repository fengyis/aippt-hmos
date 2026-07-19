import { promptAction } from '@kit.ArkUI'
import { AppTitleBar } from '../components/AppTitleBar'
import { StepIndicator, StepData } from '../components/StepIndicator'
import { PptChapter } from '../model/PptModels'
import { PptViewModel } from '../viewmodel/PptViewModel'

@ObservedV2
class OutlineState {
  @Trace chapters: PptChapter[] = []
  @Trace isCreating: boolean = false
  @Trace isCompleted: boolean = false
  @Trace isLoading: boolean = false
  @Trace from: string = ''
  @Trace query: string = ''
  @Trace filePath: string = ''
}

@Entry
@ComponentV2
struct CreateOutLinePage {
  @Consumer('navPathStack') navPathStack: NavPathStack = new NavPathStack()
  @Local state: OutlineState = new OutlineState()
  @Local pptVM: PptViewModel = new PptViewModel()

  aboutToAppear(): void {
    this.state.from = 'FROM_TEXT_BOX_CONTENT'
    this.state.query = ''
    this.createOutline()
  }

  async createOutline(): Promise<void> {
    this.state.isCreating = true
    this.state.isCompleted = false
    const ok = await this.pptVM.createOutline(this.state.query, this.state.filePath)
    if (ok) { this.state.chapters = this.pptVM.chapters; this.state.isCompleted = true }
    this.state.isCreating = false
  }

  onChapterTitleChange(index: number, text: string): void {
    if (index >= 0 && index < this.state.chapters.length) {
      this.state.chapters[index].chapterTitle = text
    }
  }

  onCreatePPT(): void {
    if (!this.state.isCompleted) { return }
    this.navPathStack.pushPathByName('ChoicePPTTemplatePage', undefined)
  }

  build() {
    NavDestination() {
      Column() {
        AppTitleBar({ title: '大纲生成', showBack: true })

        StepIndicator({
          steps: [
            new StepData('1', this.state.from === 'FROM_FILE_IMPORT' ? '导入文档' : '输入主题'),
            new StepData('2', '生成大纲'),
            new StepData('3', '选择模版'),
            new StepData('4', '生成PPT')
          ],
          currentStep: this.state.isCompleted ? 3 : (this.state.isCreating ? 1 : 2)
        })

        if (this.state.isCreating) {
          Column() {
            LoadingProgress().width(48).height(48).color('#5B3CFF')
            Text('大纲生成中，请勿退出...')
              .fontSize(14).fontColor('#999999').margin({ top: 12 })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.state.chapters, (chapter: PptChapter, index: number) => {
              ListItem() {
                Column() {
                  Row() {
                    Text(index === 0 ? '主题' : '章节')
                      .fontSize(12).fontColor('#5B3CFF')
                      .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                      .backgroundColor('#F0EBFF').borderRadius(4)
                  }.width('100%').margin({ bottom: 8 })

                  TextInput({ text: chapter.chapterTitle })
                    .fontSize(index === 0 ? 16 : 14).fontWeight(index === 0 ? FontWeight.Bold : FontWeight.Normal)
                    .backgroundColor(Color.Transparent)
                    .enabled(this.state.isCompleted)
                    .onChange((value: string) => { this.onChapterTitleChange(index, value) })
                }
                .width('100%').padding(16)
                .borderRadius(10).backgroundColor(Color.White)
                .margin({ bottom: 8 })
              }
            })
          }
          .layoutWeight(1)
          .padding({ left: 16, right: 16, top: 8 })
          .scrollBar(BarState.Off)
        }

        if (this.state.isCompleted) {
          Row() {
            Button($r('app.string.select_template'))
              .fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.White)
              .width('100%').height(48).borderRadius(24)
              .backgroundColor('#5B3CFF')
              .margin({ left: 24, right: 24, bottom: 24 })
              .onClick(() => this.onCreatePPT())
          }
          .width('100%').backgroundColor(Color.White)
        } else if (this.state.isCreating) {
          Button('停止生成')
            .fontSize(16).fontColor(Color.White)
            .width('100%').height(48).borderRadius(24)
            .backgroundColor('#E84026')
            .margin({ left: 24, right: 24, bottom: 24 })
            .onClick(() => { this.navPathStack.pop() })
        }
      }
      .width('100%').height('100%').backgroundColor('#F7F7F7')
    }
    .title('').hideTitleBar(true)
  }
}
