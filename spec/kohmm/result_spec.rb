require 'stringio'

RSpec.describe KOHMM::Result do
  let(:hmmsearch_result1) { spec_root.join('test_data', 'K00001').open }
  let(:hmmsearch_result2) { spec_root.join('test_data', 'K00004').open }
  let(:ko_file) { StringIO.new(<<~KOLIST) }
    knum	threshold	score_type	profile_type	F-measure	nseq	nseq_used	alen	mlen	eff_nseq	re/pos	definition
    K00001	170.20	domain	trim	0.244676	1458	1033	1718	320	10.61	0.590	alcohol dehydrogenase [EC:1.1.1.1]
    K00004	277.79	full	whole	0.925732	857	652	781	354	3.38	0.590	(R,R)-butanediol dehydrogenase [EC:1.1.1.4 1.1.1.- 1.1.1.303]
  KOLIST
  let(:result) { KOHMM::Result.new([hmmsearch_result1, hmmsearch_result2], ko_file) }

  after { [hmmsearch_result1, hmmsearch_result2].each(&:close) }

  describe '#for_ko' do
    subject { result.for_ko("K00001") }

    it { is_expected.to be_a_kind_of Enumerable }

    it 'has the right number of hits' do
      expect(subject.count).to eq 6
    end

    it 'includes hits of the designated KO only' do
      is_expected.to all(satisfy { |hit| hit.ko.name == "K00001" })
    end
  end

  describe '#for_gene' do
    subject { result.for_gene("apr:Apre_1614") }

    it { is_expected.to be_kind_of Enumerable }

    it 'has the right number of hits' do
      expect(subject.count).to eq 2
      expect(result.for_gene("apr:Apre_1060").count).to eq 1
    end

    it 'includes hits of the designated gene only' do
      is_expected.to all(satisfy { |hit| hit.gene_name == "apr:Apre_1614" })
    end
  end

  describe 'each hit' do
    let(:hits) { result.for_gene("apr:Apre_1614") }
    let(:hit1) { hits.find { |hit| hit.ko.name == "K00001" } }
    let(:hit2) { hits.find { |hit| hit.ko.name == "K00004" } }
    let(:hit3) { result.for_gene("apr:Apre_1060").first }

    describe '#gene_name' do
      it 'returns the right name' do
        expect(hit1.gene_name).to eq "apr:Apre_1614"
        expect(hit2.gene_name).to eq "apr:Apre_1614"
      end
    end

    describe '#ko' do
      it 'returns a KO object' do
        expect(hit1.ko).to be_kind_of KOHMM::KO
      end

      specify 'returned KO has the right name' do
        expect(hit1.ko.name).to eq "K00001"
        expect(hit2.ko.name).to eq "K00004"
      end
    end

    describe '#score' do
      it 'returns the right score' do
        expect(hit1.score).to eq 170.2
        expect(hit2.score).to eq 277.8
      end
    end

    describe '#e_value' do
      it 'returns the right E-value' do
        expect(hit1.e_value).to eq 9.5e-51
        expect(hit2.e_value).to eq 1.2e-83
      end
    end

    describe '#above_threshold?' do
      context 'when the score is equal to the threshold' do
        subject { hit1.above_threshold? }
        it { is_expected.to be_truthy }
      end

      context 'when the score is above the threshold' do
        subject { hit2.above_threshold? }
        it { is_expected.to be_truthy }
      end

      context 'when the score is below the threshold' do
        subject { hit3.above_threshold? }
        it { is_expected.to be_falsy }
      end
    end
  end
end