<?php

// Thanks to Noname @ asd2bam for giving me his old BrainBread stats code

function get_lastseen($lastseenstamp)
{
	$unixtimestamp = time();
	$lastseendate = date("D M d, Y H:i",$lastseenstamp);
	$timdiff = ($unixtimestamp - $lastseenstamp);
	
	$d = floor(($timdiff/86400));
	$h = floor((($timdiff%86400)/3600));
	$m = floor(((($timdiff%86400)%3600)/60));
	$s = floor(((($timdiff%86400)%3600)%60));
	
	$lastseenago = "";
	
	if ( $d > 0 ) { $lastseenago = $lastseenago.$d."d "; }
	if ( $h > 0 ) { $lastseenago = $lastseenago.$h."h "; }
	if ( $m > 0 ) { $lastseenago = $lastseenago.$m."m "; }
	if ( $s > 0 ) { $lastseenago = $lastseenago.$s."s "; }
	if ( $lastseenago == "" ) { $lastseenago = "0s "; }
	
	// Damn you timetravlers!
	if ( $d < 0 || $h <0 || $m < 0 || $s < 0 )
	{
		return $lastseendate."<br>Today";
	}
	else
		return $lastseendate."<br>(".$lastseenago."ago)";
}


$country = array(
	'00' => 'Unknown',
	'AF' => 'Afghanistan', 'AL' => 'Albania', 'DZ' => 'Algeria',
	'AS' => 'American Samoa', 'AD' => 'Andorra', 'AO' => 'Angola',
	'AI' => 'Anguilla', 'AQ' => 'Antarctica', 'AQ' => 'Antigua and Barbuda',
	'AR' => 'Argentina', 'AM' => 'Armenia', 'AW' => 'Aruba',
	'AU' => 'Australia', 'AT' => 'Austria', 'AZ' => 'Azerbaijan',
	'BS' => 'Bahamas', 'BH' => 'Bahrain', 'BD' => 'Bangladesh',
	'BB' => 'Barbados', 'BY' => 'Belarus', 'BE' => 'Belgium',
	'BZ' => 'Belize', 'BJ' => 'Benin', 'DM' => 'Bermuda',
	'BT' => 'Bhutan', 'BO' => 'Bolivia', 'BA' => 'Bosnia and Herzegovina',
	'BW' => 'Botswana', 'BV' => 'Bouvet Island', 'BR' => 'Brazil',
	'IO' => 'British Indian Ocean Territory', 'BN' => 'Brunei Darussalam', 'BG' => 'Bulgaria',
	'BF' => 'Burkina Faso', 'BI' => 'Burundi', 'KH' => 'Cambodia',
	'CM' => 'Cameroon', 'CA' => 'Canada', 'CV' => 'Cape Verde',
	'KY' => 'Cayman Islands', 'CF' => 'Central African Republic', 'TD' => 'Chad',
	'CL' => 'Chile', 'CN' => 'China', 'CX' => 'Christmas Island',
	'CC' => 'Cocos (Keeling) Islands', 'CO' => 'Colombia', 'KM' => 'Comoros',
	'CG' => 'Congo, Republic of the', 'Cd' => 'Congo, The Democratic Republic of the', 'CK' => 'Cook Islands',
	'CR' => 'Costa Rica', 'CI' => 'Côte d\'Ivoire', 'HR' => 'Croatia',
	'CU' => 'Cuba', 'CY' => 'Cyprus', 'CZ' => 'Czech Republic',
	'DK' => 'Denmark', 'DJ' => 'Djibouti', 'DM' => 'Dominica',
	'DO' => 'Dominican Republic', 'EC' => 'Ecuador', 'EQ' => 'Egypt',
	'SB' => 'El Salvador', 'ENGLAND' => 'England', 'EG' => 'Equatorial Guinea',
	'ER' => 'Eritrea', 'EU' => 'Europe',
	'EE' => 'Estonia', 'ET' => 'Ethiopia', 'FK' => 'Falkland Islands (Islas Malvinas)',
	'FO' => 'Faroe Islands', 'FJ' => 'Fiji', 'FI' => 'Finland',
	'FR' => 'France', 'GF' => 'French Guiana', 'PF' => 'French Polynesia',
	'TF' => 'French Southern Territories', 'GA' => 'Gabon', 'GM' => 'Gambia',
	'GE' => 'Georgia', 'DE' => 'Germany', 'GH' => 'Ghana',
	'GI' => 'Gibraltar', 'GR' => 'Greece', 'GL' => 'Greenland',
	'GD' => 'Grenada', 'GP' => 'Guadeloupe', 'GU' => 'Guam',
	'GT' => 'Guatemala', 'GN' => 'Guinea', 'GW' => 'Guinea-Bissau',
	'GY' => 'Guyana', 'HT' => 'Haiti', 'HM' => 'Heard Island and McDonald Islands',
	'VA' => 'Vatican City State', 'HN' => 'Honduras', 'HK' => 'Hong Kong',
	'HU' => 'Hungary', 'IS' => 'Iceland', 'IN' => 'India',
	'ID' => 'Indonesia', 'IR' => 'Iran, Islamic Republic of', 'IQ' => 'Iraq',
	'IE' => 'Ireland, Republic of', 'IL' => 'Israel', 'IT' => 'Italy',
	'JM' => 'Jamaica', 'JP' => 'Japan', 'JO' => 'Jordan',
	'KZ' => 'Kazakhstan', 'KE' => 'Kenya', 'KI' => 'Kiribati',
	'KP' => 'Korea, Democratic People\'s Republic of', 'KR' => 'Korea, Republic of', 'KW' => 'Kuwait',
	'KG' => 'Kyrgyzstan', 'LA' => 'Lao People\'s Democratic Republic', 'LV' => 'Latvia',
	'LB' => 'Lebanon', 'LS' => 'Lesotho', 'LR' => 'Liberia',
	'LY' => 'Libyan Arab Jamahiriya', 'LI' => 'Liechtenstein', 'LT' => 'Lithuania',
	'LU' => 'Luxembourg', 'MO' => 'Macao', 'MK' => 'Macedonia, The Former Yugoslav Republic of',
	'MG' => 'Madagascar', 'MW' => 'Malawi', 'MY' => 'Malaysia',
	'MV' => 'Maldives', 'ML' => 'Mali', 'MT' => 'Malta',
	'MH' => 'Marshall Islands', 'MQ' => 'Martinique', 'MR' => 'Mauritania',
	'MU' => 'Mauritius', 'YT' => 'Mayotte', 'MX' => 'Mexico',
	'FM' => 'Micronesia, Federated States of', 'MD' => 'Moldova, Republic of', 'MC' => 'Monaco',
	'MN' => 'Mongolia', 'MS' => 'Montserrat', 'MA' => 'Morocco',
	'MN' => 'Mozambique', 'MM' => 'Myanmar', 'NA' => 'Namibia',
	'NR' => 'Nauru', 'NP' => 'Nepal', 'NL' => 'Netherlands',
	'AN' => 'Netherlands Antilles', 'NC' => 'New Caledonia', 'NZ' => 'New Zealand',
	'NI' => 'Nicaragua', 'NE' => 'Niger', 'NG' => 'Nigeria',
	'NU' => 'Niue', 'NF' => 'Norfolk Island', 'MP' => 'Northern Mariana Islands',
	'NO' => 'Norway', 'OM' => 'Oman', 'PK' => 'Pakistan',
	'PW' => 'Palau', 'PS' => 'Palestinian Territory, Occupied', 'PA' => 'Panama',
	'PG' => 'Papua New Guinea', 'PY' => 'Paraguay', 'PE' => 'Peru',
	'PH' => 'Philippines', 'PN' => 'Pitcairn', 'PL' => 'Poland',
	'PT' => 'Portugal', 'PR' => 'Puerto Rico', 'QA' => 'Qatar',
	'RE' => 'Reunion', 'RO' => 'Romania', 'RU' => 'Russian Federation',
	'RW' => 'Rwanda', 'SH' => 'Saint Helena', 'KN' => 'Saint Kitts and Nevis',
	'LC' => 'Saint Lucia', 'PM' => 'Saint Pierre and Miquelon', 'VC' => 'Saint Vincent and the Grenadines',
	'WS' => 'Samoa', 'SM' => 'San Marino', 'ST' => 'Sao Tome and Principe',
	'SA' => 'Saudi Arabia', 'SCOTLAND' => 'Scotland', 'SN' => 'Senegal',
	'CS' => 'Serbia and Montenegro', 'SC' => 'Seychelles', 'SL' => 'Sierra Leone',
	'SG' => 'Singapore', 'SK' => 'Slovakia', 'SI' => 'Slovenia',
	'SB' => 'Solomon Islands',
	'SO' => 'Somalia', 'ZA' => 'South Africa', 'GS' => 'South Georgia and the South Sandwich Islan',
	'ES' => 'Spain', 'LK' => 'Sri Lanka', 'SD' => 'Sudan',
	'SR' => 'Suriname', 'SJ' => 'Svalbard and Jan Mayen', 'SZ' => 'Swaziland',
	'SE' => 'Sweden', 'CH' => 'Switzerland', 'SY' => 'Syrian Arab Republic',
	'TW' => 'Taiwan', 'TJ' => 'Tajikistan', 'TZ' => 'Tanzania, United Republic of',
	'TH' => 'Thailand', 'TL' => 'Timor-Leste', 'TG' => 'Togo',
	'TK' => 'Tokelau', 'TO' => 'Tonga', 'TT' => 'Trinidad and Tobago',
	'TN' => 'Tunisia', 'TR' => 'Turkey', 'TM' => 'Turkmenistan',
	'TC' => 'Turks and Caicos Islands', 'TV' => 'Tuvalu', 'UG' => 'Uganda',
	'UA' => 'Ukraine', 'AE' => 'United Arab Emirates', 'GB' => 'United Kingdom',
	'US' => 'United States', 'USN' => 'Union between Sweden and Norway', 'UM' => 'United States Minor Outlying Islands',
	'UY' => 'Uruguay', 'UZ' => 'Uzbekistan', 'VU' => 'Vanuatu',
	'VE' => 'Venezuela', 'VN' => 'Viet Nam', 'VG' => 'Virgin Islands, British',
	'VI' => 'Virgin Islands, U.S.', 'WF' => 'Wallis and Futuna', 'YE' => 'Yemen',
	'WALES' => 'Wales', 'EH' => 'Western Sahara',
	'ZM' => 'Zambia', 'ZW' => 'Zimbabwe',
);


?>
		<table id="bbstats_table" border="0" cellpadding="8" cellspacing="1" width="100%">
			<thead>
				<tr>
					<th class="toprow">Rank</th>
					<th class="toprow">SteamID</th>
					<th class="toprow">Nickname</th>
					<th class="toprow">Last Seen</th>
					<th class="toprow">EXP (level)</th>
					<th class="toprow">HP</th>
					<th class="toprow">Speed</th>
					<th class="toprow">Skill</th>
					<th class="toprow">Points left</th>
				</tr>
			</thead>
			
			<tfoot>
				<tr>
					<th class="toprow">Rank</th>
					<th class="toprow">SteamID</th>
					<th class="toprow">Nickname</th>
					<th class="toprow">Last Seen</th>
					<th class="toprow">EXP (level)</th>
					<th class="toprow">HP</th>
					<th class="toprow">Speed</th>
					<th class="toprow">Skill</th>
					<th class="toprow">Points left</th>
				</tr>
			</tfoot>
			
			<tbody>
			<?php
			while($row = mysqli_fetch_array($result_users))
			{
				if ($row['exp'] > 0) {
			?>
			<tr align="center" style="height: 30px;">
				<td class="row1" align="center" valign="middle">
					<?php
					// Everything gets listed, and orginized with the max EXP. So we don't really have todo anything here.
					$getrank++;
					echo number_format( $getrank );
					?>
				</td>
				<td class="row1" align="center" nowrap="" width="220">
					<span class="row2">
						<table cellpadding="5">
							<tbody>
								<tr>
									<td align="center">
										<?php
										echo $row['authid'];
										?>
									</td>
								</tr>
							</tbody>
						</table>
					</span>
				</td>
				<td class="row2" align="left" width="100%">
						<?php
						
						if ($row['name'] == "")
							$GetName = "Unknown";
						else
							$GetName = $row['name'];
						
						if ($row['online'] == "false")
							$GetStatus = "";
						else
							$GetStatus = "<span style='color:green'>Online</span>";
						
						if ($row['country'] == "")
							$SetCountry = "00";
						else
							$SetCountry = $row['country'];
						
						$oSteamID = new SteamID($row['authid']);
						$oSteamURL = "http://steamcommunity.com/profiles/" . $oSteamID->getSteamID64();
						
						echo "<img src='images/flags/{$SetCountry}.png' title='{$country[$SetCountry]}' height='11' width='16'> <a href='{$oSteamURL}' target='_blank'>" . $GetName . "</a> ". $GetStatus;
						?>
				</td>
				<td class="row1" align="center" nowrap="" width="220">
					<span class="row2">
						<table cellpadding="5">
							<tbody>
								<tr>
									<td align="center">
										<?php
										echo get_lastseen($row['date']);
										?>
									</td>
								</tr>
							</tbody>
						</table>
					</span>
				</td>
				<td class="row1" align="center" nowrap="" width="220">
					<span class="row2">
						<table cellpadding="5">
							<tbody>
								<tr>
									<td align="center">
										<?php
										$exp_org = $row['exp'];
										$exp_new = $exp_org/3600;
										$exp_new = floatval($exp_new);
										$exp_show = number_format($exp_new, 2, '.', '');
										echo "{$exp_show} ({$row['lvl']})";
										?>
									</td>
								</tr>
							</tbody>
						</table>
					</span>
				</td>
				<td class="row1" align="center">
					<span class="row2">
						<table cellpadding="5">
							<tbody>
								<tr>
									<td align="center">
										<?php echo $row['skill_hp']; ?>
									</td>
								</tr>
							</tbody>
						</table>
					</span>
				</td>
				<td class="row1" align="center">
					<span class="row2">
						<table cellpadding="5">
							<tbody>
								<tr>
									<td align="center">
										<?php echo $row['skill_speed']; ?>
									</td>
								</tr>
							</tbody>
						</table>
					</span>
				</td>
				<td class="row1" align="center">
					<span class="row2">
						<table cellpadding="5">
							<tbody>
								<tr>
									<td align="center">
										<?php echo $row['skill_skill']; ?>
									</td>
								</tr>
							</tbody>
						</table>
					</span>
				</td>
				<td class="row1" align="center">
					<span class="row2">
						<table cellpadding="5">
							<tbody>
								<tr>
									<td align="center">
										<?php echo $row['points']; ?>
									</td>
								</tr>
							</tbody>
						</table>
					</span>
				</td>
			</tr>
			<?php
				}
			}
			?>
			</tbody>
		</table>