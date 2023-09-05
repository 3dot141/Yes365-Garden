import {QuartzTransformerPlugin} from "../types";

export interface Options {
  support: boolean
}

const defaultOptions: Options = {
  support: false,
}

const dataviewJsRegex: RegExp = /```dataviewjs.*[\w\n\r]*```/gm

export const Dataview: QuartzTransformerPlugin<Partial<Options> | undefined> = (
  userOpts,
) => {
  const opts = { ...defaultOptions, ...userOpts }
  return {
    name: "dataview",
    textTransform(_ctx, src) {

        src = src.toString()
        return src.replaceAll(dataviewJsRegex, "");
    },
  }
}
