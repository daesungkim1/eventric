describe 'Aggregate', ->
  Aggregate   = eventric.require 'Aggregate'
  myAggregate  = null

  describe '#generateDomainEvent', ->
    eventName = null
    beforeEach ->
      myAggregate = new Aggregate 'MyAggregate', root: class Foo,
        some:
          ones:
            name: 'John'


    it 'should create a DomainEvent including changes', ->
      myAggregate.generateDomainEvent eventName
      expect(myAggregate.getDomainEvents()[0].getName()).to.equal eventName
      expect(myAggregate.getDomainEvents()[0].getAggregateChanges()).to.deep.equal
        some:
          ones:
            name: 'John'


    it 'should include the change even if the value was already present', ->
      myAggregate = new Aggregate 'MyAggregate', root: class Foo, name: 'Willy'
      myAggregate.applyProps
        name: 'Willy'

      myAggregate.generateDomainEvent()
      expect(myAggregate.getDomainEvents()[0].getAggregateChanges()).to.deep.equal
        name: 'Willy'


  describe '#getDomainEvents', ->
    it 'should return the generated domainEvents', ->
      myAggregate = new Aggregate 'MyAggregate', root: class Foo
      myAggregate.generateDomainEvent 'someEvent'
      myAggregate.generateDomainEvent 'anotherEvent'
      domainEvents = myAggregate.getDomainEvents()
      expect(domainEvents.length).to.equal 2


  describe '#applyChanges', ->
    it 'should apply given changes to properties and not track the changes', ->
      myAggregate = new Aggregate 'MyEntity', root: class Foo

      props =
        name: 'ChangedJohn'
        nested:
          structure: 'foo'
      myAggregate.applyChanges props

      json = myAggregate.toJSON()
      expect(json.name).to.equal 'ChangedJohn'
      expect(json.nested.structure).to.equal 'foo'
      myAggregate.generateDomainEvent 'someEvent'
      expect(myAggregate.getDomainEvents()[0].getAggregateChanges()).to.be.undefined


  describe '#clearChanges', ->
    it 'should clear all changes', ->
      myAggregate = new Aggregate 'A1', root: class Foo, name: 'John'
      myAggregate.id = 1

      myAggregate.clearChanges()
      myAggregate.generateDomainEvent 'someEvent'
      expect(myAggregate.getDomainEvents()[0].getAggregateChanges()).to.be.undefined
