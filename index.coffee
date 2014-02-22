
ItemPile = require 'itempile'

module.exports = (game, opts) -> new BucketPlugin game, opts

class BucketPlugin
  constructor: (@game, @opts) ->
    @registry = @game.plugins.get('voxel-registry') ? throw new Error('voxel-bucket requires voxel-registry plugin')

    opts.fluids ?= ['water', 'lava'] # TODO: fluid registry

    @fluidBuckets = {}

    opts.registerBlocks ?= true
    opts.registerItems ?= true
    opts.registerRecipes ?= true

    @enable()

  enable: () ->
    if @opts.registerItems
      @registry.registerItem 'bucket', {itemTexture: 'i/bucket_empty', onUse: @pickupFluid.bind(@)}

      ucfirst = (s) -> s.substr(0, 1).toUpperCase() + s.substring(1)

      for fluid in @opts.fluids
        bucketName = "bucket#{ucfirst fluid}"
        @registry.registerItem bucketName, {itemTexture: "i/bucket_#{fluid}", fluid: fluid, containerItem: 'bucket', onUse: @placeFluid.bind(@, fluid)}
        @fluidBuckets[fluid] = bucketName

    if @opts.registerBlocks
      for fluid in @opts.fluids
        # TODO: fluid mechanics, probably in separate module (these blocks are completely static)
        # https://github.com/deathcap/voxel-ideas/issues/1
        @registry.registerBlock fluid, {texture: "#{fluid}_still", fluid: fluid}

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

    fluidBucket = @fluidBuckets[fluid]
    return if not fluidBucket

    # remove fluid from world, and add to returned bucket item
    @game.setBlock target.voxel, 0
    return new ItemPile(fluidBucket)  # replace empty bucket with filled bucket

  placeFluid: (fluid, held, target)  ->
    console.log 'placeFluid',fluid,held,target

    return if not target

    fluidIndex = @registry.getBlockID fluid
    return if not fluidIndex?

    # set voxel and empty bucket 
    @game.setBlock target.adjacent, fluidIndex
    return new ItemPile('bucket')
