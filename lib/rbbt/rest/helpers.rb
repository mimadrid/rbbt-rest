module Sinatra
  module RbbtMiscHelpers
    def OR_matrices(m1, m2)
      samples = m1.fields
      new = TSV.setup({}, :key_field => "Ensembl Gene ID", :fields => samples)

      m1.each do |gene, values|
        new[gene] = values
      end

      m2.each do |gene, values|
        if new.include? gene
          new[gene] = new[gene].zip(values).collect do |old, new|
            case
            when old == new
              old
            else
              "TRUE"
            end
          end
        else
          new[gene] = values
        end
      end

      new
    end

    def exome_bed_file_for_genes(genes)
      bed = TSV.setup({}, :key_field => "Ensembl Exon ID", :fields => %w(chr start end gene), :type => :list)
      organism = genes.organism
      exon_info = Organism.exons(organism).tsv :fields => ["Chromosome Name", "Exon Chr Start", "Exon Chr End"], :persist => true
      exons_for = Organism.exons(organism).tsv :key_field => "Ensembl Gene ID", :fields => ["Ensembl Exon ID"], :persist => true, :merge => true, :type => :flat
      genes.each do |gene|
        exons = exons_for[gene.ensembl]
        exons.each do |exon|
          chr, start, eend = exon_info[exon]
          bed[exon] = [chr, start, eend, gene]
        end
      end
      bed
    end

    def format_name(name)
      parts = name.split("_")
      hash = parts.pop
      clean_name = parts * "_"
      "<span class='name' jobname='#{ name }'>#{ clean_name }</span> <span class='hash'>#{ hash }</span>"
    end

    def values2d3(data)
      data = data.to_single if data.respond_to? :to_single and not data.type == :single

      values = []
      data.each do |key, value|
        name = key.respond_to?(:name) ? key.name || key : key
        values << {:label => name, :value => value}
      end

      values
    end
  end
end
