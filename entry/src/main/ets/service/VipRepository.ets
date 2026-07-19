import { HttpClient } from '../network/HttpClient'
import { BaseResponse } from '../model/BaseResponse'
import { ProductBean } from '../model/ProductBean'

export class VipRepository {
  private client = HttpClient.getInstance()

  async fetchProductList(payFrom: string = ''): Promise<BaseResponse<ProductBean[]>> {
    return this.client.post<ProductBean[]>('/pay/productList', { payFrom: payFrom })
  }

  async createOrder(productId: string, paymentChannel: number): Promise<BaseResponse<Object>> {
    // PLACEHOLDER: P-S2-1 P-S2-2 P-S2-3 — 微信/支付宝/华为支付 SDK
    return this.client.post('/pay/preCreateOrder', { productId: productId, paymentChannel: paymentChannel })
  }
}
