import { preferences } from '@kit.ArkData'

const STORE_NAME = 'aippt_preferences'

export class PreferencesUtil {
  private static store: preferences.Preferences | null = null

  static async init(context: Context): Promise<void> {
    this.store = await preferences.getPreferences(context, STORE_NAME)
  }

  static async getString(key: string, def: string = ''): Promise<string> {
    if (!this.store) return def
    return await this.store.get(key, def) as string
  }

  static async putString(key: string, value: string): Promise<void> {
    if (!this.store) return
    await this.store.put(key, value)
    await this.store.flush()
  }

  static async getBool(key: string, def: boolean = false): Promise<boolean> {
    if (!this.store) return def
    return await this.store.get(key, def) as boolean
  }

  static async putBool(key: string, value: boolean): Promise<void> {
    if (!this.store) return
    await this.store.put(key, value)
    await this.store.flush()
  }

  static async getNumber(key: string, def: number = 0): Promise<number> {
    if (!this.store) return def
    return await this.store.get(key, def) as number
  }

  static async putNumber(key: string, value: number): Promise<void> {
    if (!this.store) return
    await this.store.put(key, value)
    await this.store.flush()
  }
}
