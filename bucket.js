'use strict';

const ItemPile = require('itempile');
const ucfirst = require('ucfirst');

module.exports = (game, opts) => new BucketPlugin(game, opts);
module.exports.pluginInfo = {
  loadAfter: ['voxel-registry', 'voxel-fluid'] // TODO: load after voxel-fluid dependants, too? post-init (other plugins might register other new fluids!)
};

class BucketPlugin {
  constructor(game, opts) {
    this.game = game;
    this.opts = opts;
    this.registry = game.plugins.get('voxel-registry');
    if (!this.registry) throw new Error('voxel-bucket requires "voxel-registry" plugin')
    this.fluidPlugin = game.plugins.get('voxel-fluid');
    if (!this.fluidPlugin) throw new Error('voxel-bucket requires "voxel-fluid" plugin')

    this.fluidBuckets = {};

    if (this.opts.registerBlocks === undefined) this.opts.registerBlocks = true;
    if (this.opts.registerItems === undefined) this.opts.registerItems = true;
    if (this.opts.registerRecipes === undefined) this.opts.registerRecipes = true;

    this.enable();
  }

  enable() {
    if (this.opts.registerItems) {
      this.registry.registerItem('bucket', {
        itemTexture: 'i/bucket_empty',
        onUse: this.pickupFluid.bind(this),
        displayName: 'Empty Bucket',
        creativeTab: 'fluids'
      });

      for (let fluid of this.fluidPlugin.getFluidNames()) {
        const bucketName = `bucket${ucfirst(fluid)}`;
        this.registry.registerItem(bucketName, {
          itemTexture: `i/bucket_${fluid}`,
          fluid: fluid,
          containerItem: 'bucket',
          onUse: this.placeFluid.bind(this, fluid),
          displayName: "${ucfirst(fluid)} Bucket",
          creativeTab: 'fluids'
        });

        this.fluidBuckets[fluid] = bucketName;
      }
    }

    if (this.opts.registerRecipes) {
      this.recipes = this.game.plugins.get('voxel-recipes');
      if (!this.recipes) throw new Error('voxel-bucket requires voxel-recipes plugin when opts.registerRecipes enabled');

      this.recipes.registerPositional([
        ['ingotIron', undefined, 'ingotIron'],
        ['ingotIron', 'ingotIron', 'ingotIron']
        [undefined, undefined, undefined]], // TODO: 2x3 recipe shape, not 3x3 - https://github.com/deathcap/craftingrecipes/issues/2
          new ItemPile('bucket'));
    }
  }
        

  disable() {
    // TODO
  }

  pickupFluid(held, target) {
    console.log('pickupFluid',held,target);
    if (!target) return;

    const name = this.registry.getBlockName(target.value);
    const props = this.registry.getBlockProps(name);
    if (props === undefined) return;

    const fluid = props.fluid;
    if (!fluid) return;

    const flowing = props.flowing;
    if (flowing) return; // can only pick up source blocks, not flowing

    const fluidBucket = this.fluidBuckets[fluid];
    if (!fluidBucket) return;

    // remove fluid from world, and add to returned bucket item
    this.game.setBlock(target.voxel, 0);
    return new ItemPile(fluidBucket);  // replace empty bucket with filled bucket
  }

  placeFluid(fluid, held, target) {
    console.log('placeFluid',fluid,held,target);

    if (!target) return;

    const fluidIndex = this.registry.getBlockIndex(fluid);
    if (fluidIndex === undefined) return;

    // set voxel and empty bucket
    this.game.setBlock(target.adjacent, fluidIndex);
    return new ItemPile('bucket');
  }
}

