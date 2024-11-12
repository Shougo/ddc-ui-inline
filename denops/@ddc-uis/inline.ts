import { type Context, type DdcItem } from "jsr:@shougo/ddc-vim@~7.1.0/types";
import { BaseUi } from "jsr:@shougo/ddc-vim@~7.1.0/ui";

import type { Denops } from "jsr:@denops/core@~7.0.0";
import * as fn from "jsr:@denops/std@~7.3.0/function";

export type Params = {
  highlight: string;
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
      args.uiParams.highlight,
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
      highlight: "NonText",
    };
  }
}
