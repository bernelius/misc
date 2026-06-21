#!/usr/bin/env python3
import argparse


def find_paren_positions(line):
    positions = []
    start = 0
    while True:
        pos = line.find('(', start)
        if pos == -1:
            break
        positions.append(pos)
        start = pos + 1
    return positions


def main():
    parser = argparse.ArgumentParser(
        description='Renames the channels in a Reaper ChanMap file to make the names more readable (we add spaces).'
    )
    parser.add_argument('file', help='The ChanMap file to process.')
    args = parser.parse_args()

    with open(args.file, 'r') as f:
        lines = f.readlines()

    name_lines = [(i, line) for i, line in enumerate(lines) if 'name' in line]

    if not name_lines:
        print('No channel names found.')
        return 1

    max_parens = max(line.count('(') for _, line in name_lines)

    if max_parens > 0:
        paren_positions = [find_paren_positions(line) for _, line in name_lines]

        for paren_idx in range(max_parens):
            # Find the rightmost position of this parenthesis across all lines that have one.
            max_pos = -1
            for positions in paren_positions:
                if len(positions) > paren_idx:
                    if positions[paren_idx] > max_pos:
                        max_pos = positions[paren_idx]

            # Shift each line's parenthesis to that rightmost position by inserting spaces.
            for i, positions in enumerate(paren_positions):
                if len(positions) <= paren_idx:
                    continue

                current_pos = positions[paren_idx]
                if current_pos >= max_pos:
                    continue

                spaces_to_add = max_pos - current_pos
                line_idx, line = name_lines[i]
                new_line = line[:current_pos] + ' ' * spaces_to_add + line[current_pos:]
                name_lines[i] = (line_idx, new_line)
                lines[line_idx] = new_line

                # Update positions for this line; the current paren and any later parens shifted right.
                for j in range(paren_idx, len(positions)):
                    positions[j] += spaces_to_add

    with open(args.file, 'w') as f:
        f.writelines(lines)

    return 0


if __name__ == '__main__':
    exit(main())
