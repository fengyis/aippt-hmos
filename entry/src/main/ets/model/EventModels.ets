import { ProductBean } from './ProductBean'

export class PaySuccessEvent {
  paySucc: boolean = false
  constructor(paySucc: boolean) {
    this.paySucc = paySucc
  }
}

export class LimitCampaignEvent {
  productBean: ProductBean | null = null
  constructor(productBean: ProductBean | null) {
    this.productBean = productBean
  }
}

export class LimitGiftEvent {
  productBean: ProductBean | null = null
  constructor(productBean: ProductBean | null) {
    this.productBean = productBean
  }
}

export class OaidResultEvent {
  constructor() {}
}

export class PptAddSuccessEvent {
  constructor() {}
}
