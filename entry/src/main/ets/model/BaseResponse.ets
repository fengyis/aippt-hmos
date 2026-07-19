export class BaseResponse<T> {
  code: number = 0
  msg: string = ''
  data: T | null = null

  isSuccess(): boolean {
    return this.code === 0
  }
}

export class ApiException extends Error {
  code: number
  constructor(code: number, message: string) {
    super(message)
    this.code = code
    this.name = 'ApiException'
  }
}
