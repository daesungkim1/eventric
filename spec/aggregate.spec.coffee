describe 'Aggregate', ->
  Aggregate   = eventric.require 'Aggregate'
  DomainEvent = eventric.require 'DomainEvent'

  describe '#generateDomainEvent', ->
    it 'should create a DomainEvent including changes', ->
      someProps =
        some:
          ones:
            name: 'John'
      myAggregate = new Aggregate 'MyAggregate', root: class Foo
      myAggregate.create someProps

      myAggregate.generateDomainEvent 'someEvent'
      expect(myAggregate.getDomainEvents()[0].getName()).to.equal 'someEvent'
      expect(myAggregate.getDomainEvents()[0].getAggregateChanges()).to.deep.equal someProps


    it.skip 'should include the change even if the value was already applied', ->
      class Foo
        changeName: (name) ->
          @name = 'Willy'
      myAggregate = new Aggregate 'MyAggregate', root: Foo

      domainEvent = new DomainEvent
        name: 'someEvent'
        aggregate:
          changed:
            name: 'Willy'
      myAggregate.applyDomainEvents [domainEvent]

      myAggregate.command
        name: 'changeName'
        props: ['Willy']
      myAggregate.generateDomainEvent()
      expect(myAggregate.getDomainEvents()[0].getAggregateChanges().name).to.deep.equal
        name: 'Willy'


    it 'should add the correct entity class map to the domain event', ->
      class MooEntity
      class BarEntity
      class Foo
        createEntities: ->
          @bar = new BarEntity
          @moo = [
            new MooEntity
            'someOtherValue'
            new BarEntity
          ]
      aggregateDefinition =
        root: Foo
        entities:
          'Bar': BarEntity
          'Moo': MooEntity
      myAggregate = new Aggregate 'MyAggregate', aggregateDefinition, foo: 'bar'
      myAggregate.command
        name: 'createEntities'

      myAggregate.generateDomainEvent 'someEvent'
      expect(myAggregate.getDomainEvents()[0].aggregate.entityMap).to.deep.equal
        'Bar': [
          ['bar']
          ['moo', 2]
        ]
        'Moo': [
          ['moo', 0]
        ]


  describe '#getDomainEvents', ->
    it 'should return the generated domainEvents', ->
      myAggregate = new Aggregate 'MyAggregate', root: class Foo
      myAggregate.generateDomainEvent 'someEvent'
      myAggregate.generateDomainEvent 'anotherEvent'
      domainEvents = myAggregate.getDomainEvents()
      expect(domainEvents.length).to.equal 2


  describe '#applyDomainEvents', ->
    it 'should apply given changes from domain events to properties', ->
      myAggregate = new Aggregate 'MyAggregate', root: class Foo

      domainEvent = new DomainEvent
        name: 'someEvent'
        aggregate:
          changed:
            name: 'ChangedJohn'
            nested:
              structure: 'foo'
      myAggregate.applyDomainEvents [domainEvent]

      json = myAggregate.toJSON()
      expect(json.name).to.equal 'ChangedJohn'
      expect(json.nested.structure).to.equal 'foo'
      myAggregate.generateDomainEvent 'someEvent'
      expect(myAggregate.getDomainEvents()[0].getAggregateChanges()).to.be.undefined


  describe '#command', ->
    it 'should call an aggregate method based on the given commandName together with the arguments', ->
      someParameters = [
        'something'
      ]

      class Foo
        someMethod: sandbox.stub()
      myAggregate = new Aggregate 'MyAggregate', root: Foo

      command =
        name: 'someMethod'
        params: someParameters
      myAggregate.command command


      expect(Foo::someMethod).to.have.been.calledWith command.params...


    it 'should callback with error if the command does not exist in the root', (done) ->
      myAggregate = new Aggregate 'MyAggregate', root: class Foo

      myAggregate.command
        name: 'someMethod'
        params: []
      , (error) ->
        expect(error).to.be.an.instanceof Error
        done()


    it 'should handle non array params automatically', ->
      class Foo
        someMethod: sandbox.stub()
      myAggregate = new Aggregate 'MyAggregate', root: Foo

      myAggregate.command
        name: 'someMethod'
        params: 'foo'

      expect(Foo::someMethod).to.have.been.calledWith 'foo'