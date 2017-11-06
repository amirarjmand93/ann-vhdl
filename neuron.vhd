library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity neuron is
	generic(
		inputs : integer := 3           -- Number of inputs into the neuron
	);
	port(
		clk      : in  std_logic;
		rst      : in  std_logic;
		start_i  : in  std_logic;
		input_i  : in  std_logic_bus_array(inputs - 1 downto 0);
		weight_i : in  std_logic_bus_array(inputs downto 0); -- weight(0) is bias!
		done_o   : out std_logic;
		output_o : out std_logic_bus
	);
end entity neuron;

-- rtl_synthesis off
-- rtl_synthesis on

-- McCulloch-Pitts "all-or-none" activation function (threshold)
architecture threshold of neuron is
	type state is (idle, reg_inputs, weight_mult, act_func);
	signal current_state, next_state : state;
	signal input_s                   : std_logic_bus_array(inputs - 1 downto 0);
	signal weight_s                  : std_logic_bus_array(inputs downto 0);
	signal sum_s                     : std_logic_vector(width * 2 - 1 downto 0);
	signal mult_s                    : std_logic_vector(width * 2 - 1 downto 0);
	signal n                         : std_logic_bus := std_logic_vector(to_unsigned(inputs - 1, std_logic_bus'length));
begin

	fsm_lower : process(clk, rst) is
	begin
		if rst = '1' then
			current_state <= idle;
			output_o      <= (others => '0');
			done_o        <= '0';
			input_s       <= input_i;
			weight_s      <= weight_i;
		else
			current_state <= next_state;
		end if;
	end process fsm_lower;

	fsm_upper : process(current_state, input_i, input_s, mult_s, n, start_i, sum_s, weight_s) is
	begin
		case current_state is
			when idle =>
				if start_i = '1' then
					next_state <= reg_inputs;
				else
					next_state <= current_state;
				end if;

			when reg_inputs =>
				input_s <= input_i;
				sum_s   <= x"00" & weight_s(0); -- bias is already added to sum

				next_state <= weight_mult;

			when weight_mult =>
				n      <= std_logic_vector(unsigned(n) - 1);
				mult_s <= std_logic_vector(signed(input_s(to_integer(unsigned(n)))) * signed(weight_s(to_integer(unsigned(n)))));
				sum_s  <= std_logic_vector(signed(sum_s) + signed(mult_s));

				if n = x"ff" then
					next_state <= act_func;
				else
					next_state <= current_state;
				end if;

			when act_func =>
				if sum_s(width - 1) = '1' then
					output_o <= (others => '0');
				else
					output_o <= x"01";
				end if;
				done_o <= '1';

				next_state <= idle;

		end case;

	end process fsm_upper;

end architecture threshold;
