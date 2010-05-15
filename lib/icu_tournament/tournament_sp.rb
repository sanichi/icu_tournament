require 'inifile'
require 'dbf'

module ICU
  class Tournament

=begin rdoc

== SwissPerfect

This is the format produced by the Windows program, SwissPerfect[http://www.swissperfect.com/]. It consists of three
files with the same name but different endings: <em>.ini</em> for meta data such as tournament name and tie-break
rules, <em>.trn</em> for the player details such as name and ID, and <em>.sco</em> for the results. The first
file is text and the other two are in an old binary format known as <em>DBase 3</em>.

To parse such a set of files, use either the _parse_file!_ or _parse_file_ method supplying the name of any one
of the three files or just the stem name without any ending. In case of error, such as any of the files not being
found, _parse_file!_ will throw an exception while _parse_file_ will return _nil_ and record an error message.
As well as a file name or stem name, you must also supply a start date because SwissPerfect does not record this
information.

  parser = ICU::Tournament::SwissPerfect.new
  tournament = parser.parse_file('champs', "2010-07-03")  # looks for "champs.ini", "champs.trn" and "champs.sco"
  puts parser.error unless tournament

Because the data is in three parts, some of which are in a legacy binary format, serialization to this format is
not supported. Instead, a method is provided to serialize any tournament text in the format of <em>SwissPerfects</em>
text export format, an example of which is shown below.

  No  Name                 Loc Id  Total   1     2     3

  1   Griffiths, Ryan-Rhys 6897    3       4:W   2:W   3:W
  2   Flynn, Jamie         5226    2       3:W   1:L   4:W
  3   Hulleman, Leon       6409    1       2:L   4:W   1:L
  4   Dunne, Thomas        10914   0       1:L   3:L   2:L

This format is important in Irish chess, as it's the format used to submit results to the <em>MicroSoft Access</em>
implementation of the ICU ratings database.

  swiss_perfect = tournament.serialize('SwissPerfect')

The order of players in the serialized output is always by player number and as a side effect of serialization,
the player numbers will be adjusted to ensure they range from 1 to the total number of players (i.e. renumbered
in order). If you would prefer rank-order instead, then you must first renumber the players by rank (the default
renumbering method) before serializing. For example:

  swiss_perfect = tournament.renumber.serialize('SwissPerfect')

There should be no need to explicitly rank the tournament first, as that information is already present in
SwissPerfect files (i.e. each player should already have a rank after the files have been parsed).
Additionally, the tie break rules used for the tournament will be available from:

  tournament.tie_breaks           # => [:buchholz, :harkness]

Should you wish to rank the tournament using a different set of tie-break rules, you can do something like the following:

  tournament.tie_breaks = [:wins, :blacks]
  swiss_perfect = tournament.rerank.renumber.serialize('SwissPerfect')

== Todo

* Allow parsing from 1 zip file
* Implement the extra tie-break rules that SP has

=end

    class SwissPerfect
      attr_reader :error

      TRN = {
        :dob        => "BIRTH_DATE",
        :fed        => "FEDER",
        :first_name => "FIRSTNAME",
        :gender     => "SEX",
        :id         => ["LOC_ID", "INTL_ID"],
        :last_name  => "SURNAME",
        :num        => "ID",
        :rank       => "ORDER",
        :rating     => ["LOC_RTG", "INTL_RTG"],
      } # not used: ABSENT BOARD CLUB FORB_PAIRS LATE_ENTRY LOC_RTG2 MEMO TEAM TECH_SCORE WITHDRAWAL (START_NO, BONUS used below)

      SCO = %w{ROUND WHITE BLACK W_SCORE B_SCORE W_TYPE B_TYPE}  # not used W_SUBSCO, B_SUBSCO

      # Parse SP data returning a Tournament or raising an exception on error.
      def parse_file!(file, start)
        @t = Tournament.new('Dummy', start)
        @bonus = {}
        @start_no = {}
        ini, trn, sco = get_files(file)
        parse_ini(ini)
        parse_trn(trn)
        parse_sco(sco)
        fixup
        @t.validate!(:rerank => true)
        @t
      end

      # Parse SP data returning an ICU::Tournament or a nil on failure. In the latter
      # case, an error message will be available via the <em>error</em> method.
      def parse_file(file, start)
        begin
          parse_file!(file, start)
        rescue => ex
          @error = ex.message
          nil
        end
      end

      # Serialise a tournament to SwissPerfect text export format.
      def serialize(t)
        return nil unless t.class == ICU::Tournament && t.players.size > 2;

        # Ensure a nice set of numbers.
        t.renumber(:order)

        # Widths for the rank, name and ID and the number of rounds.
        m1 = t.players.inject(2) { |l, p| p.num.to_s.length  > l ? p.num.to_s.length  : l }
        m2 = t.players.inject(4) { |l, p| p.name.length      > l ? p.name.length      : l }
        m3 = t.players.inject(6) { |l, p| p.id.to_s.length   > l ? p.id.to_s.length   : l }
        rounds = t.last_round

        # The header, followed by a blank line.
        formats = ["%-#{m1}s", "%-#{m2}s", "%-#{m3}s", "%-5s"]
        (1..rounds).each { |r| formats << "%#{m1}d  " % r }
        sp = formats.join("\t") % ['No', 'Name', 'Loc Id', 'Total']
        sp << "\r\n\r\n"

        # Adjust the round parts of the formats for players results.
        (1..t.last_round).each { |r| formats[r+3] = "%#{m1+2}s" }

        # Now add a line for each player.
        t.players.each { |p| sp << p.to_sp_text(rounds, "#{formats.join(%Q{\t})}\r\n") }

        # And return the whole lot.
        sp
      end

      private

      def get_files(file)
        file.match(/\.zip$/i) ? get_zipped_files(file) : get_bare_files(file)
      end

      def get_bare_files(file)
        file.sub!(/\.\w+$/, '')
        %w(ini trn sco).map do |p|
          q = [p, p.upcase].detect { |r| File.file? "#{file}.#{r}" }
          raise "cannot find file #{file}.#{p}" unless q
          "#{file}.#{q}"
        end
      end

      def get_zipped_files(file)
        raise "get_zip_files not implemented"
      end

      def parse_ini(file)
        begin
          ini = IniFile.load(file)
        rescue
          raise "invalid INI file"
        end
        raise "invalid INI file (no sections)" if ini.sections.size == 0
        %w(name arbiter rounds).each do |key|
          val = (ini['Tournament Info'][key.capitalize] || '').squeeze(" ").strip
          @t.send("#{key}=", val) if val.size > 0
        end
        @t.tie_breaks = ini['Standings']['Tie Breaks'].to_s.split(/,/).map do |tbid|
          case tbid.to_i             # tie break name in SwissPerfect
          when 1217 then :buchholz   # Buchholz
          when 1218 then :harkness   # Median Buchholz
          when 1219 then nil         # Progress        - not implenented yet
          when 1220 then :neustadtl  # Berger          
          when 1221 then nil         # Rating Sum      - not implemented yet
          when 1222 then :wins       # Number of Wins  
          when 1223 then nil         # Minor Scores    - not applicable
          when 1226 then nil         # Brightwell      - not applicable
          else nil
          end 
        end.find_all { |tb| tb }
      end

      def parse_trn(file)
        begin
          trn = DBF::Table.new(file)
        rescue
          raise "invalid TRN file"
        end
        raise "invalid TRN file (no records)" if trn.record_count == 0
        trn.each do |r|
          next unless r
          h = trn_record_to_hash(r)
          @t.add_player(ICU::Player.new(h.delete(:first_name), h.delete(:last_name), h.delete(:num), h))
        end
      end

      def parse_sco(file)
        begin
          sco = DBF::Table.new(file)
        rescue
          raise "invalid SCO file"
        end
        raise "invalid SCO file (no records)" if sco.record_count == 0
        sco.each do |r|
          next unless r
          hs = sco_record_to_hashes(r)
          hs.each { |h| @t.add_result(ICU::Result.new(h.delete(:round), h.delete(:player), h.delete(:score), h)) }
        end
      end

      def trn_record_to_hash(r)
        @bonus[r.attributes["ID"]] = %w{BONUS MEMO}.inject(0.0){ |b,k| b > 0.0 ? b : r.attributes[k].to_f }
        @start_no[r.attributes["ID"]] = r.attributes["START_NO"]
        TRN.inject(Hash.new) do |hash, pair|
          keys = pair[1]
          keys = [keys] unless keys.class == Array
          val, val2 = keys.map { |k| r.attributes[k] }
          case pair[0]
          when :fed    then val = val && val.match(/^[A-Z]{3}$/i) ? val.upcase : nil
          when :gender then val = val.to_i > 0 ? %w(M F)[val.to_i-1] : nil
          when :id     then val = val.to_i > 0 ? val : (val2.to_i > 0 ? val2 : nil)
          when :rating then val = val.to_i > 0 ? val : (val2.to_i > 0 ? val2 : nil)
          when :title  then val = val.to_i > 0 ? %w(GM WGM IM WIM FM WFM)[val.to_i-1] : nil
          end
          hash[pair[0]] = val unless val.nil? || val == ''
          hash
        end
      end

      def sco_record_to_hashes(record)
        r, w, b, ws, bs, wt, bt = SCO.map { |k| record.attributes[k] }
        hashes = []
        if w > 0 && b > 0 && ws + bs == 2
          hashes.push({ :round => r, :player => w, :score => %w(L D W)[ws], :opponent => b, :colour => 'W' })
          hashes.last[:rateable] = false unless wt == 1 && bt == 1
        else
          hashes.push({ :round => r, :player => w, :score => %w(L D W)[ws], :colour => 'W' }) if w > 0
          hashes.push({ :round => r, :player => b, :score => %w(L D W)[bs], :colour => 'B' }) if b > 0
        end
        hashes
      end

      def fixup
        fix_number_of_rounds
        fix_missing_results
        fix_bonuses
        fix_numbering
      end

      def fix_number_of_rounds
        rounds = @t.last_round
        @t.rounds = rounds
      end

      def fix_missing_results
        @t.players.each { |p| @t.add_result(ICU::Result.new(1, p.num, 'L')) if p.results.size == 0 }
      end

      def fix_bonuses
        @t.players.each do |p|
          bonus = @bonus[p.num] || 0
          next unless bonus > 0

          # Try to distribute the bonus in half-points to rounds where the player has no result.
          (1..@t.rounds).each do |r|
            result = p.find_result(r)
            next if result
            bonus = bonus - 0.5
            p.add_result(ICU::Result.new(r, p.num, 'D'))
            break if bonus <= 0
          end
          next unless bonus > 0

          # Try to distribute the bonus in half-points to rounds where the player has unrated results.
          (1..@t.rounds).each do |r|
            result = p.find_result(r)
            next unless result
            next if result.opponent
            next if result.score == 'W'
            bonus = bonus - 0.5
            result.score = result.score == 'D' ? 'W' : 'D'
            break if bonus <= 0
          end
        end
      end

      def fix_numbering
        @t.renumber(@start_no)
      end
    end
  end

  class Player
    # Format a player's record as it would appear in an SP text export file.
    def to_sp_text(rounds, format)
      attrs = [num.to_s, name, id.to_s, ('%.1f' % points).sub(/\.0/, '')]
      (1..rounds).each do |r|
        result = find_result(r)
        attrs << (result ? result.to_sp_text : " : ")
      end
      format % attrs
    end
  end

  class Result
    # Format a player's result as it would appear in an SP text export file.
    def to_sp_text
      sp = opponent ? opponent.to_s : '0'
      sp << ':'
      if rateable
        sp << score
      else
        sp << case score
        when 'W' then '+'
        when 'L' then '-'
        else '='
        end
      end
    end
  end
end
