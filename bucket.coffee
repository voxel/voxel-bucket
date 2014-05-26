
ItemPile = require 'itempile'
ucfirst = require 'ucfirst'

module.exports = (game, opts) -> new BucketPlugin game, opts
module.exports.pluginInfo =
  loadAfter: ['voxel-registry', 'voxel-fluid'] # TODO: load after voxel-fluid dependants, too? post-init (other plugins might register other new fluids!)

class BucketPlugin
  constructor: (@game, @opts) ->
    @registry = @game.plugins.get('voxel-registry') ? throw new Error('voxel-bucket requires "voxel-registry" plugin')
    @fluidPlugin = @game.plugins.get('voxel-fluid') ? throw new Error('voxel-bucket requires "voxel-fluid" plugin')

    @fluidBuckets = {}

    opts.registerBlocks ?= true
    opts.registerItems ?= true
    opts.registerRecipes ?= true

    @enable()

  enable: () ->
    if @opts.registerItems
      @registry.registerItem 'bucket',
        itemTexture: 'i/bucket_empty'
        onUse: @pickupFluid.bind(@)
        displayName: 'Empty Bucket'
        creativeTab: 'fluids'

      for fluid in @fluidPlugin.getFluidNames()
        bucketName = "bucket#{ucfirst fluid}"
        @registry.registerItem bucketName,
          itemTexture: "i/bucket_#{fluid}"
          fluid: fluid
          containerItem: 'bucket'
          onUse: @placeFluid.bind(@, fluid)
          displayName: "#{ucfirst fluid} Bucket"
          creativeTab: 'fluids'

        @fluidBuckets[fluid] = bucketName

    if @opts.registerRecipes
      @recipes = @game.plugins.get('voxel-recipes') ? throw new Error('voxel-bucket requires voxel-recipes plugin when opts.registerRecipes enabled')

      @recipes.registerPositional [
        ['ingotIron', undefined, 'ingotIron'],
        ['ingotIron', 'ingotIron', 'ingotIron']
        [undefined, undefined, undefined]], # TODO: 2x3 recipe shape, not 3x3 - https://github.com/deathcap/craftingrecipes/issues/2
          new ItemPile('bucket')
        

  disable: () ->
    # TODO

  pickupFluid: (held, target) ->
    console.log 'pickupFluid',held,target
    return if not target

    name = @registry.getBlockName target.value
    props = @registry.getBlockProps name
    return if not props?

    fluid = props.fluid
    return if not fluid

    flowing = props.flowing
    return if flowing # can only pick up source blocks, not flowing

    fluidBucket = @fluidBuckets[fluid]
    return if not fluidBucket

    # remove fluid from world, and add to returned bucket item
    @game.setBlock target.voxel, 0
    return new ItemPile(fluidBucket)  # replace empty bucket with filled bucket

  placeFluid: (fluid, held, target)  ->
    console.log 'placeFluid',fluid,held,target

    return if not target

    fluidIndex = @registry.getBlockIndex fluid
    return if not fluidIndex?

    # set voxel and empty bucket 
    @game.setBlock target.adjacent, fluidIndex
    return new ItemPile('bucket')
