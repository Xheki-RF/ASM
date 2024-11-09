"""==============================================INITIAL DATA SECTION==============================================="""

# List of commands
command_dict = {
    "lds": 0b000,  # DESCRIPTION: Takes 1 positional arguments: memory address
    "add": 0b001,  # DESCRIPTION: Takes 1 positional argument: register
    "out": 0b010,  # DESCRIPTION: Takes 1 positional argument: register
    "mov": 0b011,  # DESCRIPTION: Takes 1 positional argument: register
    "jnz": 0b100,  # DESCRIPTION: Takes 1 positional argument: procedure address
    "lda": 0b101,  # DESCRIPTION: Takes 1 positional argument: address
    "dec": 0b110,  # DESCRIPTION: Takes 1 positional argument: register
    "inc": 0b111,  # DESCRIPTION: Takes 1 positional argument: register
}

# OVERVIEW: Lists for separated codes (after separating one huge code into fractions)
# Commands' codes
cmd_code_list_proc = []
# Values' codes
val_code_list_proc = []

size = 8

# Mixed memory of command and data
cmd_dt_memory = [0] * 2**size
# Registers' memory: R0...R15
reg_data = [0] * 2**4

# OVERVIEW: Special registers
# Special register memory: Accumulator - stores the result of summation
ACM = 0
# Special register memory: Memory slot address - stores the current slot address of memory data
MSA = 0
# Special register memory: Temporary - stores the value after LDS function execution. It may also store other
# temporary values if necessary
TMP = 0


# OVERVIEW: Flags
# Flag to stop program counter
stop_flag = False
# Flag needed for JNZ
is_zero = False

# Program counter
pc = 0
# Current command code in execution
cc = 0
""""============================================END OF INITIAL DATA SECTION========================================="""


"""==================================================FUNCTION SECTION=============================================="""


# OVERVIEW: Function for parsing the input
def command_parser(x):
    global procedure_list, procedure_address, cmd_amount
    x = x.lower()

    if "lds" in x:
        cmd = x[:3]
        value = x[4:-1]
        cmd_amount += 1
        command_list.append([cmd, value])

    elif "mov" in x:
        cmd = x[:3]
        value = x[4:-1]
        cmd_amount += 1
        command_list.append([cmd, value])

    elif "add" in x:
        cmd = x[:3]
        value = x[4:-1]
        cmd_amount += 1
        command_list.append([cmd, value])

    elif "out" in x:
        cmd = x[:3]
        value = x[4:-1]
        cmd_amount += 1
        command_list.append([cmd, value])

    elif "jnz" in x:
        cmd = x[:3]
        value = x[4:]
        cmd_amount += 1
        command_list.append([cmd, value])

    elif "lda" in x:
        cmd = x[:3]
        value = x[4:-1]
        cmd_amount += 1
        command_list.append([cmd, value])

    elif "dec" in x:
        cmd = x[:3]
        value = x[4:-1]
        cmd_amount += 1
        command_list.append([cmd, value])

    elif "inc" in x:
        cmd = x[:3]
        value = x[4:-1]
        cmd_amount += 1
        command_list.append([cmd, value])

    else:
        procedure_list.append(x[:-1])
        procedure_address.append(cmd_amount)


# OVERVIEW: Function for encoding commands after parsing and merging into one code
def line_encoding(x):
    full_cmd_lst = []
    print("=" * 40)

    for i in range(len(x)):
        for j in range(0, len(x[i]), 2):
            command_code = command_dict[x[i][j]]
            print("Command code:", bin(command_code))

            # DESCRIPTION: LDS
            if command_code == 0b000:
                print("LDS")
                if x[i][j + 1] != "msa":
                    value_code = int(x[i][j + 1], 2)
                    print("Memory slot address code:", bin(value_code))
                else:
                    value_code = 0xFE
                    print("Register code:", bin(value_code))

            # DESCRIPTION: ADD
            elif command_code == 0b001:
                print("ADD")
                value_code = int((x[i][j + 1])[1:])
                print("Register code:", bin(value_code))

            # DESCRIPTION: OUT
            elif command_code == 0b010:
                print("OUT")
                if x[i][j + 1] == "acm":
                    value_code = 0xFF
                    print("Register code:", bin(value_code))

                elif x[i][j + 1] == "msa":
                    value_code = 0xFE
                    print("Register code:", bin(value_code))

                else:
                    value_code = int((x[i][j + 1])[1:])
                    print("Register code:", bin(value_code))

            # DESCRIPTION: MOV
            elif command_code == 0b011:
                print("MOV")
                value_code = int((x[i][j + 1])[1:])
                print("Register code:", bin(value_code))

            # DESCRIPTION: JNZ
            elif command_code == 0b100:
                print("JNZ")
                value_code = procedure_dict[x[i][j + 1]]
                print("Procedure address to go to code:", bin(value_code))

            # DESCRIPTION: LDA
            elif command_code == 0b101:
                print("LDA")
                value_code = int(x[i][j + 1], 2)
                print("Load number to MSA:", bin(value_code))

            # DESCRIPTION: DEC
            elif command_code == 0b110:
                print("DEC")
                if x[i][j + 1] != "msa":
                    value_code = int((x[i][j + 1])[1:])
                    print("Register code:", bin(value_code))
                else:
                    value_code = 0xFE
                    print("Register code:", bin(value_code))

            # DESCRIPTION: INC
            else:
                print("INC")
                if x[i][j + 1] != "msa":
                    value_code = int((x[i][j + 1])[1:])
                    print("Register code:", bin(value_code))
                else:
                    value_code = 0xFE
                    print("Register code:", bin(value_code))

            processor_code = command_code << 8 | value_code
            print("Full command:", bin(processor_code))

            full_cmd_lst.append(processor_code)

        print("=" * 40)

    return full_cmd_lst


# OVERVIEW: Function for separating commands after merging them into one code
def code_to_sep_proc():
    for i in range(cmd_amount):
        # Command to separate
        cmd_to_sep = cmd_dt_memory[i]

        # Getting command code
        cmd_code = cmd_to_sep >> 8

        # Getting register/memory slot code
        val_code = cmd_to_sep & 0b00011111111

        cmd_code_list_proc.append(cmd_code)
        val_code_list_proc.append(val_code)


# OVERVIEW: Function for getting current command code in execution
def get_code():
    var = cmd_code_list_proc[pc]
    return var


# OVERVIEW: Function for adding the value from certain register to special register ACM
def add_with_shift(a):
    result = 0
    carry = 0

    for i in range(8):
        bit_a = (a >> i) & 1
        bit_b = (ACM >> i) & 1

        current_sum = bit_a ^ bit_b ^ carry
        result |= current_sum << i

        carry = (bit_a & bit_b) | (carry & (bit_a ^ bit_b))

    return result


# OVERVIEW: Function for jumping to certain program address
def transition_check():
    global pc, MSA, TMP, stop_flag, is_zero

    TMP = pc
    pc = val_code_list_proc[pc]

    if is_zero:
        if TMP < (cmd_amount - 1):
            pc = TMP
            pc += 1
            is_zero = False
        else:
            stop_flag = True


# OVERVIEW: Function for defining the command and calling certain function: lds, add, out
def command_execution():
    global TMP, MSA, ACM, pc, stop_flag, is_zero

    # DESCRIPTION: LDS
    if cmd_code_list_proc[pc] == 0b000:  # Code 0
        print("LDS")
        if val_code_list_proc[pc] == 0xFE:
            TMP = cmd_dt_memory[MSA]
        else:
            TMP = cmd_dt_memory[val_code_list_proc[pc]]
        print("TMP:", TMP)
        if pc == cmd_amount - 1:
            stop_flag = True
        else:
            pc += 1

    # DESCRIPTION: ADD
    elif cmd_code_list_proc[pc] == 0b001:  # Code 1
        print("ADD")
        ACM = add_with_shift(reg_data[val_code_list_proc[pc]])
        print("SUM:", ACM)
        if pc == cmd_amount - 1:
            stop_flag = True
        else:
            pc += 1

    # DESCRIPTION: OUT
    elif cmd_code_list_proc[pc] == 0b010:  # Code 2
        print("OUT")
        if val_code_list_proc[pc] == 0xFF:
            print("Data out:", ACM)
            if pc == cmd_amount - 1:
                stop_flag = True
            else:
                pc += 1
        else:
            print("Data out:", reg_data[val_code_list_proc[pc]])
            if pc == cmd_amount - 1:
                stop_flag = True
            else:
                pc += 1

    # DESCRIPTION: MOV
    elif cmd_code_list_proc[pc] == 0b011:  # Code 3
        print("MOV")
        reg_data[val_code_list_proc[pc]] = TMP
        print(reg_data)
        if pc == cmd_amount - 1:
            stop_flag = True
        else:
            pc += 1

    # DESCRIPTION: JMP
    elif cmd_code_list_proc[pc] == 0b100:  # Code 4
        print("JMP")
        transition_check()

    # DESCRIPTION: LDA
    elif cmd_code_list_proc[pc] == 0b101:  # Code 5
        print("LDA")
        MSA = val_code_list_proc[pc]
        print("MSA:", MSA)
        if pc == cmd_amount - 1:
            stop_flag = True
        else:
            pc += 1

    # DESCRIPTION: DEC
    elif cmd_code_list_proc[pc] == 0b110:  # Code 6
        print("DEC")
        reg_data[val_code_list_proc[pc]] -= 1

        if reg_data[val_code_list_proc[pc]] == 0:
            is_zero = True

        print(reg_data)
        if pc == cmd_amount - 1:
            stop_flag = True
        else:
            pc += 1

    # DESCRIPTION: INC
    else:
        print("INC")
        MSA += 1
        print("MSA:", MSA)
        if pc == cmd_amount - 1:
            stop_flag = True
        else:
            pc += 1


""""============================================END OF FUNCTION SECTION============================================="""


""""==================================================MAIN SECTION=================================================="""
mem_data = []
command_list = []
procedure_list = []
procedure_address = []
cmd_amount = 0
command_list_full = []

while True:
    b = input()

    if "mem" in b:
        y = b[4:-1].split(",")
        for i in y:
            mem_data.append(int(i))

    elif b == "begin":
        continue

    elif b == "end":
        break

    else:
        command_parser(b)

print(command_list)

procedure_dict = {
    procedure_list[i]: procedure_address[i] for i in range(len(procedure_list))
}
print("Procedures' markers:", procedure_dict)

command_list_full = line_encoding(command_list)
print("List of commands (merged into one):", command_list_full)

# DESCRIPTION: Upload command list and array data to command_data memory
for i in range(len(command_list_full)):
    cmd_dt_memory[i] = command_list_full[i]

for i in range(len(mem_data)):
    cmd_dt_memory[i + (2**size // 2)] = mem_data[i]

print("Command/memory data:", cmd_dt_memory)

print("Amount of commands:", cmd_amount)

code_to_sep_proc()

print("Commands' codes list:", cmd_code_list_proc)
print("Values' codes:", val_code_list_proc)

print("=" * 40)

while True:
    print("Program counter:", pc)
    cc = get_code()
    command_execution()
    print("=" * 40)
    if stop_flag:
        break
    else:
        continue
