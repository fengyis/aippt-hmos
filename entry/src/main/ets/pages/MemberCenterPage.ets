import { promptAction } from '@kit.ArkUI'
import { AppTitleBar } from '../components/AppTitleBar'
import { ProductBean } from '../model/ProductBean'
import { UserDataModel, getUserData } from '../model/UserDataModel'

@ObservedV2
class VipState {
  @Trace products: ProductBean[] = []
  @Trace selectedIndex: number = 0
  @Trace paymentChannel: number = 1
  @Trace agreementChecked: boolean = false
  @Trace isLoading: boolean = false
  @Trace paySuccess: boolean = false
}

@Entry
@ComponentV2
struct MemberCenterPage {
  @Consumer('navPathStack') navPathStack: NavPathStack = new NavPathStack()
  @Local state: VipState = new VipState()
  @Local user: UserDataModel = getUserData()

  aboutToAppear(): void {
    if (this.user.isVip()) {
      promptAction.showToast({ message: '已经是会员了' })
      this.navPathStack.pop()
      return
    }
    this.loadProducts()
  }

  loadProducts(): void {
    this.state.isLoading = true
    try {
      // FWD-REF: P-S02-001 resolve_by=Slice 2 Step 3c — VipRepository.fetchProductList()
      this.state.products = []
    } finally {
      this.state.isLoading = false
    }
  }

  selectProduct(index: number): void {
    this.state.selectedIndex = index
  }

  onCreateOrder(): void {
    if (!this.state.agreementChecked) {
      promptAction.showToast({ message: '请先阅读并同意服务条款和隐私政策' })
      return
    }
    if (this.state.products.length === 0) {
      return
    }
    // FWD-REF: P-S02-002 resolve_by=Slice 2 Step 3c — createOrder + launch payment SDK
    // PLACEHOLDER: P-S2-1 resolve_by=Slice 2 Step 3c — WeChat Pay
    // PLACEHOLDER: P-S2-2 resolve_by=Slice 2 Step 3c — Alipay
    // PLACEHOLDER: P-S2-3 resolve_by=Slice 2 Step 3c — Huawei Pay
  }

  build() {
    NavDestination() {
      Column() {
        AppTitleBar({ title: $r('app.string.member_center'), showBack: true,
          onBackClick: () => this.navPathStack.pop() })

        if (this.state.isLoading) {
          LoadingProgress().width(48).height(48).margin({ top: 100 })
        } else {
          Scroll() {
            Column() {
              // Product cards horizontal scroll
              Text('选择会员套餐').fontSize(18).fontWeight(FontWeight.Bold).margin({ left: 16, top: 24 })

              Scroll() {
                Row({ space: 12 }) {
                  ForEach(this.state.products, (product: ProductBean, index: number) => {
                    Column() {
                      Text(product.showNowPrice)
                        .fontSize(24).fontWeight(FontWeight.Bold)
                        .fontColor(index === this.state.selectedIndex ? '#5B3CFF' : '#333333')
                      if (product.showOriginalPrice.length > 0) {
                        Text(product.showOriginalPrice)
                          .fontSize(12).fontColor('#999999')
                          .decoration({ type: TextDecorationType.LineThrough })
                      }
                      Text(product.showDesc)
                        .fontSize(12).fontColor('#666666').margin({ top: 8 })
                    }
                    .width(140).padding(16)
                    .borderRadius(12)
                    .border({
                      width: index === this.state.selectedIndex ? 2 : 1,
                      color: index === this.state.selectedIndex ? '#5B3CFF' : '#E8E8E8'
                    })
                    .backgroundColor(index === this.state.selectedIndex ? '#F8F6FF' : Color.White)
                    .onClick(() => this.selectProduct(index))
                  })
                }.padding({ left: 16, right: 16 })
              }
              .scrollable(ScrollDirection.Horizontal)
              .width('100%')
              .margin({ top: 16 })

              // Payment methods
              Text('选择支付方式').fontSize(16).fontWeight(FontWeight.Bold).margin({ left: 16, top: 28 })

              Row() {
                Column() {
                  Image($r('app.media.icon_wechat_pay')).width(36).height(36)
                  Text($r('app.string.wechat_pay')).fontSize(12).fontColor('#333333')
                  if (this.state.paymentChannel === 1) {
                    Image($r('app.media.select_pay_method_checked')).width(20).height(20).margin({ top: 4 })
                  } else {
                    Image($r('app.media.select_pay_method_uncheck')).width(20).height(20).margin({ top: 4 })
                  }
                }
                .padding(16).borderRadius(12)
                .border({ width: this.state.paymentChannel === 1 ? 2 : 1, color: this.state.paymentChannel === 1 ? '#5B3CFF' : '#E8E8E8' })
                .onClick(() => { this.state.paymentChannel = 1 })
                .margin({ left: 16 })

                Column() {
                  Image($r('app.media.icon_ali_pay')).width(36).height(36)
                  Text($r('app.string.ali_pay')).fontSize(12).fontColor('#333333')
                  if (this.state.paymentChannel === 2) {
                    Image($r('app.media.select_pay_method_checked')).width(20).height(20).margin({ top: 4 })
                  } else {
                    Image($r('app.media.select_pay_method_uncheck')).width(20).height(20).margin({ top: 4 })
                  }
                }
                .padding(16).borderRadius(12)
                .border({ width: this.state.paymentChannel === 2 ? 2 : 1, color: this.state.paymentChannel === 2 ? '#5B3CFF' : '#E8E8E8' })
                .onClick(() => { this.state.paymentChannel = 2 })
                .margin({ left: 16 })
              }

              // Agreement
              Row() {
                Checkbox().select(this.state.agreementChecked).selectedColor('#5B3CFF')
                  .onChange((value: boolean) => { this.state.agreementChecked = value })
                Text($r('app.string.pay_agreement_text')).fontSize(12).fontColor('#999999')
              }
              .margin({ top: 24, left: 16 })

              // Pay button
              Button($r('app.string.pay_now'))
                .fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.White)
                .width('100%').height(48).borderRadius(24)
                .backgroundColor('#5B3CFF')
                .margin({ top: 24, left: 24, right: 24, bottom: 40 })
                .onClick(() => this.onCreateOrder())
            }
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
      }
      .width('100%').height('100%').backgroundColor(Color.White)
    }
    .title('').hideTitleBar(true)
  }
}
