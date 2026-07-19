@ComponentV2
export struct StepIndicator {
  @Param steps: StepData[] = []
  @Param currentStep: number = 0

  build() {
    Row() {
      ForEach(this.steps, (step: StepData, index: number) => {
        Row() {
          Column() {
            Text(step.number)
              .fontSize(12)
              .fontColor(index <= this.currentStep ? Color.White : '#999999')
              .width(24)
              .height(24)
              .borderRadius(12)
              .backgroundColor(index <= this.currentStep ? '#5B3CFF' : '#E8E8E8')
              .textAlign(TextAlign.Center)
              .fontWeight(FontWeight.Bold)
          }
          Text(step.title)
            .fontSize(13)
            .fontColor(index <= this.currentStep ? '#5B3CFF' : '#999999')
            .margin({ left: 6 })
          if (index < this.steps.length - 1) {
            Divider()
              .width(28)
              .height(2)
              .color(index < this.currentStep ? '#5B3CFF' : '#E8E8E8')
              .margin({ left: 8, right: 8 })
          }
        }
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }
}

export class StepData {
  number: string = ''
  title: string = ''
  constructor(number: string, title: string) {
    this.number = number
    this.title = title
  }
}
