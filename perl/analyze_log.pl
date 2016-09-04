#!/usr/bin/perl

# written by Alexander Samoilov for analyzing log file after 'generate_traces --analyze' run
# prints statistics how much each kernel incomes to the total gputime

my $rec = {};
my $total_gputime = 0;
while (<>) {
    if (/gputime=(\d+\.\d+)/) {
        my $ln = $_;
        my $gputime = $1;
        chomp($ln);
        if ($ln =~ /(\d+)\s*:\s*(.*)(gputime=\d+\.\d+)/) {
            my $kernelno = $1;
            my $kernelname = $2;
            $total_gputime += $gputime;
            if ($kernelname =~ /(\w+)</) {
                my $kernelbase = $1;
                my $old = $rec{$kernelbase};
                my $number_of_invocations = 1;
                my $tot_gputime_this_kernel = $gputime;
                if (defined $old) {
                    $number_of_invocations += $old->{number_of_invocations};
                    $tot_gputime_this_kernel += $old->{gputime},
                }
                $rec{$kernelbase} = {
                    number_of_invocations => $number_of_invocations,
                    gputime => $tot_gputime_this_kernel,
                }
            }
        }
    }
}

# print unsorted sequence
printf "Total gpu time: %g\n",$total_gputime;
## printf "%-64s %21s %21s %14s\n", "kernel", "number of invocations", "cumulative gpu time", "percentage%";
## foreach $key (keys (%rec)) {
##     my $r = $rec{$key};
##     printf "%-64s %21d %21g %14g%%\n", $key, $r->{number_of_invocations}, $r->{gputime}, 100.0 * ($r->{gputime} / $total_gputime);
## }

# we can sort only container with a random access - an array
my @list;
foreach $key (keys (%rec)) {
    my $r = $rec{$key};
    push @list,
    {
        kernelbase  => $key,
        no_of_calls => $r->{number_of_invocations},
        totaltime   => $r->{gputime},
    }
}

my @sorted_list = sort {$b->{totaltime} <=> $a->{totaltime} } @list;
printf "%-4s %-64s %21s %21s %15s %15s\n", "no: ", "kernel", "number of calls", "cumulative gpu time", "percentage%", "cumul. percentage%";
my $no = 0;
my $perc_acc = 0;
foreach my $item (@sorted_list) {
    my $perc = 100.0 * ($item->{totaltime} / $total_gputime);
    $perc_acc += $perc;
    printf "%-4d %-64s %21d %21g %14.4f%% %14.4f%%\n", $no++, $item->{kernelbase}, $item->{no_of_calls}, $item->{totaltime}, $perc, $perc_acc;
}
