function FHSSwithGFSK_verify_ber(varargin)
%FHSSWITHGFSK_VERIFY_BER  BER sweep of the model FHSSwithGFSK (or FHSSwithGFSK_BLEhop) against reference data.
%
%   >> FHSSwithGFSK_verify_ber                          % default sweep 0..14 dB, a few minutes
%   >> FHSSwithGFSK_verify_ber('Quick',true)            % 0,10,14 dB with fewer bits
%   >> FHSSwithGFSK_verify_ber('Model','FHSSwithGFSK_BLEhop')
%
%   For each Eb/N0 it simulates N bits, counts errors itself from the logged bits (not from the Compute BER block),
%   gives the 95 % binomial confidence interval  p +- 1.96*sqrt(p(1-p)/N),  and prints PASS/FAIL against
%     (a) the coherent MSK bound  Pb = Q(sqrt(2 Eb/N0))   - no receiver may be below it
%     (b) my Monte-Carlo reference of this receiver (numpy, 200 kHz sample-based, 1e5..4e6 bits per point)
%   The model must already be built and calibrated by FHSSwithGFSK_build (Tx Delay, Sampling Delay, Slicer are read from the model).

ip = inputParser;
addParameter(ip, 'Model', 'FHSSwithGFSK');
addParameter(ip, 'Quick', false);
parse(ip, varargin{:});
mdl = ip.Results.Model;
if ~bdIsLoaded(mdl), load_system(mdl); end

% reference data (Eb/N0 dB, BER, 95 % CI) from the Monte-Carlo run of the same chain
ref = [ ...
    0  3.409e-01 6.6e-03
    2  2.787e-01 6.2e-03
    4  2.111e-01 5.7e-03
    6  1.336e-01 4.7e-03
    8  6.629e-02 3.4e-03
   10  3.137e-02 2.4e-03
   12  1.151e-02 1.5e-03
   14  2.452e-03 4.0e-04
   16  4.203e-04 7.3e-05
   18  2.564e-05 5.0e-06];

if ip.Results.Quick, eb = [0 10 14];            nbits = [3000 6000 20000];
else,                eb = [0 4 8 10 12 14];    nbits = [3000 4000 6000 10000 20000 60000]; end

lag = str2double(get_param([mdl '/Tx Delay'], 'DelayLength'));
fprintf('Model %s, Tx Delay (receiver latency) = %d bits\n', mdl, lag);
fprintf('\n Eb/N0   bits     errors   BER        95%% CI           coherent bound   reference (CI)         verdict\n');
allok = true;
for k = 1:numel(eb)
    set_param([mdl '/AWGN Channel'], 'EbNo', num2str(eb(k)));
    set_param(mdl, 'StopTime', sprintf('%.15g', nbits(k)*1e-3));
    t0 = tic;
    o = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    tx = double(squeeze(o.logsout.getElement('txbit').Values.Data));
    rx = double(squeeze(o.logsout.getElement('rxbit').Values.Data));
    skip = 20;
    n = min(numel(tx), numel(rx)) - lag - skip;
    e = sum(rx(lag+skip+1 : lag+skip+n) ~= tx(skip+1 : skip+n));
    p = e/n;  ci = 1.96*sqrt(max(p*(1-p), 1e-12)/n);
    bound = 0.5*erfc(sqrt(2*10^(eb(k)/10))/sqrt(2));         % Q(sqrt(2 g))
    i = find(ref(:,1) == eb(k), 1);
    ok1 = p + ci > bound;                                     % not below the coherent bound
    if isempty(i), ok2 = true; rtxt = '      -       ';
    else
        ok2 = abs(p - ref(i,2)) <= 2*sqrt(ci^2/3.84 + (ref(i,3)/1.96)^2) + 1e-12;   % within 2 sigma of the reference
        rtxt = sprintf('%.3e (%.1e)', ref(i,2), ref(i,3));
    end
    v = 'PASS'; if ~(ok1 && ok2), v = 'FAIL'; allok = false; end
    fprintf('%5g  %7d  %6d   %.3e  +-%.1e   %.3e        %s   %s   (%.0f s)\n', eb(k), n, e, p, ci, bound, rtxt, v, toc(t0));
end
set_param([mdl '/AWGN Channel'], 'EbNo', '10');
if allok, fprintf('\nRESULT: BER agrees with the reference and respects the coherent bound.\n');
else,     fprintf('\nRESULT: SOME POINTS FAILED - send me this output.\n'); end
fprintf('Note: fewer than ~100 errors per point means the CI is wide; raise nbits for the high-SNR points.\n');
end
