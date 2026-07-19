import { AppTitleBar } from '../components/AppTitleBar'
import { promptAction } from '@kit.ArkUI'

enum RefundStatus { IDLE, LOADING, SUCCESS, FAILED }

@ObservedV2
class RefundState {
  @Trace status: RefundStatus = RefundStatus.IDLE
  @Trace operateType: number = 0
  @Trace message: string = ''
}

@Entry
@ComponentV2
struct RefundProgressPage {
  @Consumer('navPathStack') navPathStack: NavPathStack = new NavPathStack()
  @Local state: RefundState = new RefundState()

  aboutToAppear(): void {
    // deferred: requires VIP backend API — placeholder until F002 Slice 2
    this.state.status = RefundStatus.LOADING
    setTimeout(() => {
      // Simulate: FWD-REF → replace with actual API call
      this.state.status = RefundStatus.SUCCESS
    }, 2000)
  }

  onRetry(): void {
    this.state.status = RefundStatus.LOADING
    // deferred: requires VIP backend API — placeholder until F002 Slice 2
  }

  getOperateTitle(): string {
    return this.state.operateType === 0 ? '取消续费' : '申请退款'
  }

  build() {
    NavDestination() {
      Column() {
        AppTitleBar({ title: this.getOperateTitle(), showBack: true, onBackClick: () => this.navPathStack.pop() })

        Column() {
          if (this.state.status === RefundStatus.LOADING) {
            LoadingProgress().width(48).height(48).color('#5B3CFF')
            Text('处理中...').fontSize(14).fontColor('#999999').margin({ top: 12 })
          } else if (this.state.status === RefundStatus.SUCCESS) {
            SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
              .fontSize(56).fontColor(['#4CAF50'])
            Text(this.state.operateType === 0 ? '取消续费成功' : '退款申请已提交')
              .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333333').margin({ top: 16 })
            Button('我知道了').fontSize(14).fontColor(Color.White).backgroundColor('#5B3CFF')
              .width(160).height(40).borderRadius(20).margin({ top: 24 })
              .onClick(() => this.navPathStack.pop())
          } else if (this.state.status === RefundStatus.FAILED) {
            SymbolGlyph($r('sys.symbol.xmark_circle_fill'))
              .fontSize(56).fontColor(['#E84026'])
            Text(this.state.message || '操作失败').fontSize(16).fontColor('#333333').margin({ top: 16 })
            Button('重试').fontSize(14).fontColor(Color.White).backgroundColor('#5B3CFF')
              .width(160).height(40).borderRadius(20).margin({ top: 24 })
              .onClick(() => this.onRetry())
          }
        }
        .layoutWeight(1).justifyContent(FlexAlign.Center)
      }
      .width('100%').height('100%').backgroundColor(Color.White)
    }
    .title('').hideTitleBar(true)
  }
}
