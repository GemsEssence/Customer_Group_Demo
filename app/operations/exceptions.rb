module Exceptions
  class ReceivedMoreThanDeliveredException < StandardError; end;
  class InvalidRecordException < StandardError; end;
  class NegativeQuantityException < StandardError; end;
end
