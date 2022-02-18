# frozen_string_literal: true

class Barcode
  attr_reader :barcode
  def initialize(barcode)
    @barcode = barcode
  end

  def valid?
    return false unless barcode.present? && bc_ints.present? && bc_ints.length == 14
    barcode.to_s[-1, 1].to_i == check_digit
  end

  def check_digit
    # To calculate the checksum:
    # Start with the total set to zero
    total = 0
    # and scan the 13 digits from left to right:
    # removed .scan(/\d/).map { |i| i.to_i } AF 7.x treats barcode as a FIXNUM
    # barcode_as_string = self.send(:barcode).to_s
    13.times do |i|
      # If the digit is in an even-numbered position (2, 4, 6...) add it to the total.
      if (i + 1).even?
        total += bc_ints[i]
        # If the digit is in an odd-numbered position (1, 3, 5...):
      else
        # multiply the digit by 2.
        product = bc_ints[i] * 2
        # If the product is equal to or greater than 10 subtract 9 from the product.
        product -= 9 if product >= 10
        # Then add the product to the total.
        total += product
      end
    end
    # After all digits have been processed, divide the total by 10 and take the remainder.
    rem = total % 10
    # If the remainder = 0, that is the check digit. If the remainder is not
    # zero, the check digit is 10 minus the remainder.
    rem.zero? ? 0 : 10 - rem
  end

  def bc_ints
    @bc_ints ||= barcode.to_s.scan(/\d/).map(&:to_i)
  end
end
