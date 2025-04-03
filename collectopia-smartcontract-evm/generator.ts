import GeneratorInterface, {
  GeneratorInitPropsInterface,
  ItemsAttributes,
} from "@hashlips-lab/art-engine/dist/common/generators/generator.interface";
import InputsManager from "@hashlips-lab/art-engine/dist/utils/managers/inputs/inputs.manager";
import { listOfFilterClothes } from "./filters/tattooExcludeClothes";
import { isHaveFlareFilter } from "./filters/isHaveFlare";
import { listOfFilterHair } from "./filters/headGearExcludeHair";
import * as path from "path";
import { Console } from "console";
const random_seed_1 = require("random-seed");
const crypto_1 = require("crypto");
const ITEM_ATTRIBUTES_GENERATOR_INTERFACE_V1 =
  "ItemAttributesGeneratorInterface@v1";
const IMAGE_LAYERS_GENERATOR_INTERFACE_V1 = "ImageLayersGeneratorInterface@v1";

interface ExampleCustomInterface {
  example: string;
}

interface IItemsAttributes {
  [key: string]: string;
}

export class CustomGenerator
  implements GeneratorInterface<ExampleCustomInterface>
{
  inputsManager!: InputsManager;

  dataSet!: string;

  data: any;
  startIndex!: number;
  endIndex!: number;
  rmg: any;

  constructor(constructorProps: any) {
    this.dataSet = constructorProps.dataSet;
    this.startIndex = constructorProps.startIndex;
    this.endIndex = constructorProps.endIndex;
    if (
      this.endIndex < this.startIndex ||
      this.startIndex + this.endIndex < 1
    ) {
      throw new Error(
        `The startIndex property needs to be less than the endIndex property`
      );
    }
  }

  public async init(props: GeneratorInitPropsInterface): Promise<void> {
    this.inputsManager = props.inputsManager;
    this.data = this.inputsManager.get(this.dataSet);
    this.rmg = random_seed_1.create(
      this.dataSet + this.constructor.name + props.seed
    );
  }

  public async generate(): Promise<ItemsAttributes<ExampleCustomInterface>> {
    const items: any = {};
    const dnas = new Set();
    let uid = this.startIndex;

    while (uid <= this.endIndex) {
      const itemAttributes: any = {};
      let itemAssets: any = [];
      let layer: any;
      let filterSex: any;
      let tattoo: any;
      let isHaveFlare: any = true;
      let isHaveFaceGear = true;
      let headGear: any;
      let eyeColor: any;

      let whileContinue = false;
      for (layer of Object.values(this.data.layers)) {
        let filterObj: any = layer.options;
        
        //filter clothes base on tattoo
        if (tattoo != undefined && layer.name == "6_CLOTHES") {
          const listOfFilterNumber = listOfFilterClothes(tattoo);
          console.log("TATOO =====>", JSON.stringify(tattoo));
          console.log("CLOTHES =====>", JSON.stringify(layer));
          filterObj = Object.keys(filterObj).reduce((acc: any, key) => {
            // Extract the number from the key
            const match = key.match(/(\d+)/);
            const number = match ? parseInt(match[0], 10) : null;

            // If the number is not in the listOfNumbers, add the key-value pair to the new object
            if (number !== null && !listOfFilterNumber.includes(number)) {
              acc[key] = filterObj[key];
            }
            return acc;
          }, {});
        }
        

        //filer hairs base on headgear
        if (headGear != undefined && layer.name == "9_HAIR") {
          const listOfFilterNumber = listOfFilterHair(headGear);
          filterObj = Object.keys(filterObj).reduce((acc: any, key) => {
            // Extract the number from the key
            const match = key.match(/(\d+)/);
            const number = match ? parseInt(match[0], 10) : null;

            // If the number is not in the listOfNumbers, add the key-value pair to the new object
            if (number !== null && !listOfFilterNumber.includes(number)) {
              acc[key] = filterObj[key];
            }
            return acc;
          }, {});
        }

        if (filterSex != undefined) {
          filterObj = Object.entries(filterObj)
            .filter(([key, value]) => !key.startsWith(filterSex))
            .reduce((acc: any, [key, value]) => {
              acc[key] = value;
              return acc;
            }, {});
        } else {
          filterObj = layer.options;
        }

        if (layer.name == "91_EYES_FLARE" && eyeColor) {
          filterObj = Object.keys(filterObj)
            .filter((key) => key.includes(eyeColor) || key === "FLARE-None")
            .reduce((acc: any, key) => {
              acc[key] = filterObj[key];
              return acc;
            }, {});
        }
        

        //console.log(filterObj);

        // let flag = false;
        // while(!flag){
        //     try{
              
        //     }
        //     catch{

        //     }
          
        // }

        console.log("filterObj x ----> ", filterObj);
        if(Object.keys(filterObj).length == 0){
          whileContinue = true;
          break;
        }
        console.log("filterObj ===>", filterObj);
        itemAttributes[layer.name] = this.selectRandomItemByWeight(filterObj);
        //flag = true;
        if (isHaveFaceGear == false && layer.name == "8_FACEGEAR") {
          itemAttributes["8_FACEGEAR"] = "FACEGEAR-None";
        }
        if (isHaveFlare == false && layer.name == "91_EYES_FLARE") {
          itemAttributes["91_EYES_FLARE"] = "FLARE-None";
        }
        if (layer.name == "3_BODY") {
          filterSex = this.getSexOfElement(itemAttributes[layer.name]);
        }
        if (layer.name == "4_EYES") {
          eyeColor = itemAttributes[layer.name].split("_")[1];
        }
        if (layer.name == "5_TATTOO") {
          tattoo = this.getTattoo(itemAttributes[layer.name]);
        }
        if (layer.name == "8_FACEGEAR" && isHaveFlare) {
          isHaveFlare = isHaveFlareFilter(itemAttributes[layer.name]);
        }
        if (layer.name == "7_HEADGEAR" && isHaveFlare) {
          isHaveFlare = isHaveFlareFilter(itemAttributes[layer.name]);
          headGear = itemAttributes[layer.name];
          if (itemAttributes[layer.name] == "HEADGEAR-14") {
            isHaveFaceGear = false;
          }
        }
        // console.log(tattoo);
      }
      if(whileContinue){
        continue;
      }

      // Compute DNA
      const itemDna = this.calculateDna(itemAttributes);
      if (dnas.has(itemDna)) {
        console.log(`Duplicate DNA entry, generating one more...`);
        continue;
      }
      console.log("JSON.stringify(itemAttributes, null, 2)");
      console.log(JSON.stringify(itemAttributes, null, 2));

      dnas.add(itemDna);

      // Compute assets
      for (const attributeName of Object.keys(itemAttributes)) {
        const layer = this.data.layers[attributeName];
        const option = layer.options[itemAttributes[attributeName]];
        let assets: any[] = [];
        for (const edgeCaseUid of Object.keys(option.edgeCases)) {
          const [matchingTrait, matchingValue] = edgeCaseUid.split("#");
          if (matchingValue === itemAttributes[matchingTrait]) {
            assets = assets.concat(option.edgeCases[edgeCaseUid].assets);
            break;
          }
        }

        if (assets.length === 0) {
          assets = assets.concat(option.assets);
        }
        itemAssets = itemAssets.concat(
          assets.map((asset: any) => ({
            path: path.join(this.data.basePath, asset.path),
            xOffset: layer.baseXOffset + asset.relativeXOffset,
            yOffset: layer.baseYOffset + asset.relativeYOffset,
            zOffset: layer.baseZOffset + asset.relativeZOffset,
          }))
        );
      }
      items[uid.toString()] = [
        {
          kind: ITEM_ATTRIBUTES_GENERATOR_INTERFACE_V1,
          data: {
            dna: itemDna,
            attributes: itemAttributes,
          },
        },
        {
          kind: IMAGE_LAYERS_GENERATOR_INTERFACE_V1,
          data: {
            assets: itemAssets,
          },
        },
      ];

      uid++;
      break;
    }

    return items;
  }

  getSexOfElement(string: string) {

    const firstTwoCharacters = string.substring(0, 2);

    if (firstTwoCharacters == "M_") {
      return "F_";
    } else if (firstTwoCharacters == "F_") {
      return "M_";
    }
  }

  getTattoo(string: string) {
    if (string.includes("TATTOO")) {
      return string;
    }
  }

  calculateDna(attributes: any) {
    const dnaSource = Object.keys(attributes)
      .map((key) => [key, attributes[key]])
      .sort((a, b) => {
        const nameA = a[0].toUpperCase();
        const nameB = b[0].toUpperCase();
        if (nameA < nameB) {
          return -1;
        }
        if (nameA > nameB) {
          return 1;
        }
        return 0;
      });
    return crypto_1
      .createHash("sha1")
      .update(JSON.stringify(dnaSource))
      .digest("hex");
  }

  selectRandomItemByWeight(options: any) {
    //console.log("Key1 =>>>>>>>>>>>>>>>>", options);
    const totalWeight: any = Object.values(options).reduce(
      (accumulator, currentValue: any) => accumulator + currentValue.weight,
      0
    );
    let randomNumber = this.rmg.random() * totalWeight;
    for (const key of Object.keys(options)) {

      //console.log("Key2 =>>>>>>>>>>>>>>>>",key);

      if (randomNumber < options[key].weight) {
        //console.log("Key3 =>>>>>>>>>>>>>>>>", options[key]);
        return key;
      }
      randomNumber -= options[key].weight;
    }
    throw new Error("Couldn't pick any random option...", options);
  }
}

