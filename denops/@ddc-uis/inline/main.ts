import { type Context, type DdcItem } from "@shougo/ddc-vim/types";
import { BaseUi } from "@shougo/ddc-vim/ui";

import type { Denops } from "@denops/std";
import * as fn from "@denops/std/function";

export type Params = {
  checkNextWordMatched: boolean;
  highlight: string;
  maxWidth: number;
};

export class Ui extends BaseUi<Params> {
  override async show(args: {
    denops: Denops;
    context: Context;
    completePos: number;
    items: DdcItem[];
    uiParams: Params;
  }): Promise<void> {
    await args.denops.call(
      "ddc#ui#inline#_show",
      args.completePos,
      args.items,
      args.uiParams,
    );
  }

  override async skipCompletion(args: {
    denops: Denops;
  }): Promise<boolean> {
    // Skip for other popup
    const checkNative = await fn.pumvisible(args.denops) !== 0;
    const checkPum = await fn.exists(args.denops, "pum#visible") &&
      await args.denops.call("pum#visible") as boolean;
    return checkNative || checkPum;
  }

  override async hide(args: {
    denops: Denops;
  }): Promise<void> {
    await args.denops.call("ddc#ui#inline#_hide");
  }

  override async visible(args: {
    denops: Denops;
  }): Promise<boolean> {
    return await args.denops.call("ddc#ui#inline#visible") as boolean;
  }

  override params(): Params {
    return {
      checkNextWordMatched: false,
      highlight: "ComplMatchIns",
      maxWidth: 200,
    };
  }
}
