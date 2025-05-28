# frozen_string_literal: true
=begin
IntensityManager is a utility class that allows you to manage "intensity" values across continuous numeric ranges.
It supports two operations:
    - `add(from, to, amount)` — adds a value to all segments between `from` (inclusive) and `to` (exclusive).
    - `set(from, to, amount)` — sets a value across all segments in the given range, overwriting any existing values.

Segments are defined by their start positions (integers), and intensity values are integers.

Example usage:
    manager = IntensityManager.new
    manager.set(0, 10, 5)    # sets intensity 5 from 0 to 10
    manager.add(5, 15, 3)    # adds 3 from 5 to 15
    manager.intensities      # => {0=>5, 5=>8, 10=>3, 15=>0}

Public methods:
    - `add(from, to, amount)` => updates internal state and returns sorted intensity hash
    - `set(from, to, amount)` => overwrites intensities in range and returns sorted intensity hash
    - `intensities` => returns internal intensity hash
=end
class IntensityManager
    attr_reader :intensities
  
    def initialize
        @intensities = {}
        @params = {}
    end
  
    # Add `amount` to all intensity segments between `from` and `to`.
    # @param from [Integer]
    # @param to [Integer]
    # @param amount [Integer]
    # @return [Hash] sorted intensity hash
    def add(from, to, amount)
        validate_and_set_params(from, to, amount)
        update_intensities(:add)
    end
    
    # Set `amount` to all intensity segments between `from` and `to`.
    # @param from [Integer]
    # @param to [Integer]
    # @param amount [Integer]
    # @return [Hash] sorted intensity hash
    def set(from, to, amount)
        validate_and_set_params(from, to, amount)
        update_intensities(:set)
    end
  
    private
  
    def validate_and_set_params(from, to, amount)
        # Ensure all parameters are integers
        unless from.is_a?(Integer) and to.is_a?(Integer) and amount.is_a?(Integer)
            raise ArgumentError, "from, to, and amount must be integers"
        end
        
        # Ensure from < to
        raise ArgumentError, "'from' must be less than 'to'" if from >= to

        # Set the parameters hash
        @params = { from: from, to: to, amount: amount }
    end

    def update_intensities(action)  
        # Skip if first update is a no-op      
        return @intensities if @intensities.empty? and @params[:amount] == 0

        ensure_segment_bounds_set

        if action == :add
            apply_intensities
        elsif action == :set
            apply_intensities(overwrite: true)
        end
        
        prune_zero_segments
        @intensities.sort.to_h
    end

    # Ensures both `from` and `to` are keys in the intensity hash,
    # initializing them with previous segment values or 0.
    def ensure_segment_bounds_set
        @intensities[@params[:from]] ||= get_previous_segment_intensity(@params[:from]) || 0

        # If `to` becomes the last segment bound, initialize it to 0
        if new_max_segment_bound?
            @intensities[@params[:to]] = 0
        else
            @intensities[@params[:to]] ||= get_previous_segment_intensity(@params[:to]) || 0
        end
    end

    def max_segment_bound
        sorted_segments.last
    end

    def new_max_segment_bound?
        @params[:to] >= max_segment_bound
    end

    def sorted_segments
        @intensities.keys.sort
    end

    # Gets intensity of the segment that immediately precedes the given start
    def get_previous_segment_intensity(current_segment_start)
        previous_segment_start = sorted_segments.reverse.find { |s| s < current_segment_start }
        @intensities[previous_segment_start] if previous_segment_start
    end

    # Applies intensity changes to all segments between `from` and `to`
    # If `overwrite` is true, it sets the intensity to the specified amount,
    # otherwise it adds the specified amount to the existing intensity.
    # @param overwrite [Boolean] whether to overwrite existing intensities
    def apply_intensities(overwrite: false)
        get_segments_to_update.each do |segment|
            @intensities[segment] = overwrite ? @params[:amount] : @intensities[segment] + @params[:amount]
        end
    end

    # Identifies which segments should be updated based on the `from` and `to` parameters.
    def get_segments_to_update
        segment_starts = sorted_segments
        from_index = segment_starts.index(@params[:from])
        to_index = segment_starts.index(@params[:to])

        # If `@params[:to]` extends beyond the current maximum segment, 
        # exclude the `to` boundary from the update range (`...`) since it will be a new zero segment.
        # Otherwise, include it (`..`) because it's already part of the existing segment structure.
        new_max_segment_bound? ? segment_starts[from_index...to_index] : segment_starts[from_index..to_index]
    end

    # Removes unneeded zero values from beginning and end of intensity hash
    def prune_zero_segments
        drop_leading_zeros
        drop_lagging_zeros
    end

    # Remove all leading segments with zero value
    def drop_leading_zeros
        @intensities = @intensities.sort.drop_while { |_, v| v == 0 }.to_h
    end

    # Remove trailing zeros except the last one
    def drop_lagging_zeros
        reversed = @intensities.sort.reverse
        keys_to_delete = []
        zero_values_buffer = []
      
        reversed.each do |key, value|
            if value == 0
                zero_values_buffer << key
            else
                # Keep the last zero before the non-zero
                keys_to_delete += zero_values_buffer.reverse[1..] if zero_values_buffer.size > 1
                break
            end
        end
      
        keys_to_delete.each { |key| @intensities.delete(key) }
    end
end
