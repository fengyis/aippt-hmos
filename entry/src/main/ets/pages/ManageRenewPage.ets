import { AppTitleBar } from '../components/AppTitleBar'

@ObservedV2
class RenewState {
  @Trace signStatus: number = 0
  @Trace canRefund: number = 0
  @Trace renewPrice: string = ''
  @Trace expireTime: string = ''
  @Trace isLoading: boolean = false
}

@Entry
@ComponentV2
struct ManageRenewPage {
  @Consumer('navPathStack') navPathStack: NavPathStack = new NavPathStack()
  @Local state: RenewState = new RenewState()

  aboutToAppear(): void {
    // FWD-REF: P-S02-004 resolve_by=Slice 2 Step 3c — renewViewModel.requestRenewInfo()
  }

  onCancelRenew(): void {
    this.navPathStack.pushPathByName('RefundProgressPage', { operateType: 0 })
  }

  onRefund(): void {
    this.navPathStack.pushPathByName('RefundProgressPage', { operateType: 1 })
  }

  build() {
    NavDestination() {
      Column() {
        AppTitleBar({ title: '续订管理', showBack: true, onBackClick: () => this.navPathStack.pop() })

        Column() {
          if (this.state.signStatus === 1) {
            Text('签约自动续费中').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#333333')
            Text(`到期时间: ${this.state.expireTime}`).fontSize(14).fontColor('#999999').margin({ top: 8 })
            Text(`续费价格: ${this.state.renewPrice}`).fontSize(14).fontColor('#666666').margin({ top: 4 })
            Button('取消续费').fontSize(14).fontColor('#E84026').backgroundColor(Color.Transparent)
              .border({ width: 1, color: '#E84026' }).borderRadius(20)
              .width(200).height(40).margin({ top: 24 })
              .onClick(() => this.onCancelRenew())
          } else if (this.state.canRefund === 1) {
            Text('未签约').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#333333')
            Button('申请退款').fontSize(14).fontColor('#E84026').backgroundColor(Color.Transparent)
              .border({ width: 1, color: '#E84026' }).borderRadius(20)
              .width(200).height(40).margin({ top: 24 })
              .onClick(() => this.onRefund())
          } else {
            Text('未签约').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#333333')
            Button('购买VIP').fontSize(14).fontColor(Color.White).backgroundColor('#5B3CFF')
              .borderRadius(20).width(200).height(40).margin({ top: 24 })
              .onClick(() => this.navPathStack.pushPathByName('MemberCenterPage', undefined))
          }
        }
        .layoutWeight(1).justifyContent(FlexAlign.Center)
      }
      .width('100%').height('100%').backgroundColor(Color.White)
    }
    .title('').hideTitleBar(true)
  }
}
