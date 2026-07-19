import { StepIndicator, StepData } from '../components/StepIndicator'

@ObservedV2
class GuideState {
  @Trace step: number = 0
  @Trace swiperAutoPlay: boolean = true
  @Trace countdown: number = 5
}

@Entry
@ComponentV2
struct GuidePage {
  @Consumer('navPathStack') navPathStack: NavPathStack = new NavPathStack()
  @Local state: GuideState = new GuideState()
  private countdownTimer: number = -1
  private readonly stepTitles: string[] = ['选择场景', '智能生成', '一键排版', '海量模板', '版权素材', '开始创作']
  private readonly progressValues: number[] = [20, 40, 60, 80, 100, 120]

  aboutToAppear(): void {
    // Guide flag managed by GuideViewModel.markGuideShown()
  }

  onNext(): void {
    if (this.state.step < 5) {
      this.state.step++
    } else {
      this.finishGuide()
    }
  }

  onPrev(): void {
    if (this.state.step > 0) {
      this.state.step--
    }
  }

  finishGuide(): void {
    this.navPathStack.clear()
    this.navPathStack.pushPathByName('HomePage', undefined)
  }

  getProgress(): number {
    return this.state.step < this.progressValues.length ? this.progressValues[this.state.step] : 100
  }

  getStepContent(index: number): string {
    const contents = [
      '选择您需要的PPT使用场景',
      'AI智能生成PPT大纲和内容',
      '一键排版，专业美观',
      '海量模板任您挑选',
      '丰富的版权素材库',
      '5秒倒计时自动进入'
    ]
    return contents[index] ?? ''
  }

  build() {
    NavDestination() {
      Column() {
        Progress({ value: this.getProgress(), total: 100, type: ProgressType.Linear })
          .width('100%').height(4)
          .color('#5B3CFF').backgroundColor('#F5F6FA')

        StepIndicator({
          steps: this.stepTitles.map((t: string, i: number) => new StepData((i + 1).toString(), t)),
          currentStep: this.state.step
        })

        Column() {
          Text(this.getStepContent(this.state.step))
            .fontSize(20).fontWeight(FontWeight.Bold)
            .fontColor('#1C1C1C')
            .textAlign(TextAlign.Center)
            .margin({ top: 60 })

          if (this.state.step === 4) {
            Swiper() {
              ForEach(['#5B3CFF', '#3C2AF8', '#7C25FF'], (color: string) => {
                Column() {
                  Column().width(300).height(200).borderRadius(16).backgroundColor(color)
                }
                .width('100%').justifyContent(FlexAlign.Center)
              })
            }
            .autoPlay(this.state.swiperAutoPlay)
            .width('100%').height(240)
            .margin({ top: 32 })
          }

          if (this.state.step === 5) {
            Column() {
              Text(`${this.state.countdown}`)
                .fontSize(64).fontWeight(FontWeight.Bold)
                .fontColor('#5B3CFF')
              Text('秒后自动进入')
                .fontSize(14).fontColor('#999999').margin({ top: 8 })
            }
            .margin({ top: 60 })
          }
        }
        .layoutWeight(1)

        Row() {
          if (this.state.step > 0 && this.state.step < 5) {
            Button('上一步')
              .fontSize(14).fontColor('#666666').backgroundColor('#F0F0F0')
              .width(120).height(44).borderRadius(22)
              .onClick(() => this.onPrev())
          }
          Blank()
          Button(this.state.step < 5 ? '下一步' : '立即进入')
            .fontSize(14).fontColor(Color.White).backgroundColor('#5B3CFF')
            .width(this.state.step > 0 ? 120 : 200).height(44).borderRadius(22)
            .onClick(() => this.onNext())
        }
        .width('100%').padding({ left: 24, right: 24, bottom: 32 })
      }
      .width('100%').height('100%').backgroundColor(Color.White)
    }
    .title('').hideTitleBar(true)
  }
}
