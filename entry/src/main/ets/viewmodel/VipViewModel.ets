import { ProductBean } from '../model/ProductBean'
import { VipRepository } from '../service/VipRepository'

@ObservedV2
export class VipViewModel {
  @Trace products: ProductBean[] = []
  @Trace selectedIndex: number = 0
  @Trace paymentChannel: number = 1
  @Trace agreementChecked: boolean = false
  @Trace isLoading: boolean = false
  @Trace paySuccess: boolean = false
  @Trace errorMessage: string = ''

  private repository: VipRepository = new VipRepository()

  async fetchProductList(payFrom: string = ''): Promise<void> {
    this.isLoading = true
    try {
      const resp = await this.repository.fetchProductList(payFrom)
      if (resp.isSuccess() && resp.data) {
        this.products = resp.data
      }
    } finally {
      this.isLoading = false
    }
  }

  async createOrder(): Promise<void> {
    if (!this.agreementChecked) {
      this.errorMessage = '请先阅读并同意服务条款和隐私政策'
      return
    }
    if (this.products.length === 0) return
    const product = this.products[this.selectedIndex]
    // PLACEHOLDER: P-S2-1 P-S2-2 P-S2-3 resolve_by=Slice 2 Step 3c — WeChat/Alipay/Huawei Pay SDK
    await this.repository.createOrder(product.productId, this.paymentChannel)
  }
}
