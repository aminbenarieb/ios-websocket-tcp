from twisted.internet.protocol import Factory, Protocol
from twisted.internet import reactor

class AminChat(Protocol):
	def connectionMade(self):
		self.factory.clients.append(self)
		print "cliens are ", self.factory.clients
	def connectionLost(self, reason):
		self.factory.clients.remove(self)
		print "client", self, " lost connection, reason: ", reason
	def dataReceived(self, data):
		a = data.split(":")
		print a

		if len(a) > 1:
			command = a[0]
			content = a[1].rstrip()

			msg = ""
			if command == "iam":
				self.name = content
				msg = self.name + " has joined"

			elif command == "msg":
				msg = self.name + ": " + content
				print msg

			for c in self.factory.clients:
				c.message(msg)

	def message(self, message):
		self.transport.write(message + '\n')

factory = Factory()
factory.clients = []
factory.protocol = AminChat
reactor.listenTCP(81, factory)
print "Amin Chat server started"
reactor.run()